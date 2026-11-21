"""HTTP routes. Bound to 127.0.0.1 only, so nothing outside this Mac can reach it."""

import gc
import json
import threading
import time
import traceback
from http.server import BaseHTTPRequestHandler

import loader
import logcapture
import mock


def make_handler(state, hooks):
    """Builds a handler class bound to this server's state."""

    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def log_message(self, fmt, *args):
            pass  # request lines would drown out AirLLM's own log

        def do_GET(self):
            if self.path.startswith("/health"):
                body = state.snapshot()
                body["log"] = logcapture.recent()
                return self._json(200, body)
            self._json(404, {"error": "not found"})

        def do_POST(self):
            try:
                body = self._read_json()
            except ValueError as e:
                return self._json(400, {"error": f"bad json: {e}"})
            routes = {"/load": self._load, "/unload": self._unload, "/stop": self._stop, "/chat": self._chat}
            route = routes.get(self.path)
            if route is None:
                return self._json(404, {"error": "not found"})
            route(body)

        def _load(self, body):
            model_id = (body.get("model") or "").strip()
            if not model_id:
                return self._json(400, {"error": "model is required"})
            problem = state.begin_loading(model_id)
            if problem:
                return self._json(409, {"error": problem})
            args = (state, hooks, model_id, body.get("hf_token"), loader.load_options(body))
            threading.Thread(target=loader.load, args=args, daemon=True).start()
            self._json(202, {"ok": True})

        def _unload(self, body):
            state.unload()
            gc.collect()
            self._json(200, {"ok": True})

        def _stop(self, body):
            state.cancel.set()
            self._json(200, {"ok": True})

        def _chat(self, body):
            if state.model is None:
                return self._json(409, {"error": "No model loaded"})
            if not state.generation_lock.acquire(blocking=False):
                return self._json(409, {"error": "Already generating"})
            try:
                state.cancel.clear()
                state.generating = True
                self._start_stream()
                emit = self._throttled_emitter()
                try:
                    self._run_generation(body, emit)
                except Exception as e:
                    traceback.print_exc()
                    emit({"type": "error", "message": f"{type(e).__name__}: {e}"})
                self._end_stream()
            finally:
                state.generating = False
                state.generation_lock.release()

        def _run_generation(self, body, emit):
            messages = body.get("messages") or []
            max_tokens = int(body.get("max_new_tokens") or 256)
            if state.mock:
                return mock.generate(state, messages, max_tokens, emit)
            import generation

            generation.generate(state, hooks, messages, max_tokens, float(body.get("temperature") or 0), emit)

        def _throttled_emitter(self):
            """Sends events as NDJSON chunks. Progress is capped near 20 per second,
            which is plenty for a progress bar and keeps small models from flooding the app."""
            last = [0.0]

            def emit(event):
                if event["type"] == "progress":
                    now = time.time()
                    edge = event["layer"] in (0, event["total"])
                    if now - last[0] < 0.05 and not edge:
                        return
                    last[0] = now
                self._chunk((json.dumps(event) + "\n").encode())

            return emit

        # Plumbing

        def _start_stream(self):
            self.send_response(200)
            self.send_header("Content-Type", "application/x-ndjson")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Transfer-Encoding", "chunked")
            self.end_headers()

        def _chunk(self, data):
            try:
                self.wfile.write(f"{len(data):X}\r\n".encode() + data + b"\r\n")
                self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                state.cancel.set()  # the app went away, so stop wasting disk reads

        def _end_stream(self):
            try:
                self.wfile.write(b"0\r\n\r\n")
                self.wfile.flush()
            except OSError:
                pass

        def _read_json(self):
            length = int(self.headers.get("Content-Length") or 0)
            return json.loads(self.rfile.read(length) or b"{}") if length else {}

        def _json(self, code, obj):
            data = json.dumps(obj).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

    return Handler
