"""Runs the real HTTP server in demo mode and talks to it like the app does."""

import json
import threading
import time
import unittest
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer

import helpers  # noqa: F401  (puts backend/ on the path)
import logcapture
from airllm_hooks import Hooks
from http_handler import make_handler
from state import ServerState


class DemoServerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        logcapture.install()
        cls.state = ServerState(mock=True)
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), make_handler(cls.state, Hooks(cls.state.cancel)))
        cls.base = f"http://127.0.0.1:{cls.server.server_address[1]}"
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()

    def request(self, path, body=None):
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base + path, data=data, method="POST" if data else "GET",
                                     headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=30) as response:
            return response.status, response.read().decode()

    def wait_for_model(self):
        for _ in range(100):
            if json.loads(self.request("/health")[1])["model_id"]:
                return
            time.sleep(0.1)
        self.fail("demo model never finished loading")

    def test_load_then_chat_streams_events(self):
        status, _ = self.request("/load", {"model": "demo/model"})
        self.assertEqual(status, 202)
        self.wait_for_model()

        _, body = self.request("/chat", {"messages": [{"role": "user", "content": "hi"}], "max_new_tokens": 4})
        events = [json.loads(line) for line in body.splitlines() if line]
        kinds = {e["type"] for e in events}
        self.assertTrue({"progress", "token", "done"} <= kinds)
        done = events[-1]
        self.assertEqual(done["type"], "done")
        self.assertEqual(done["tokens"], 4)
        self.assertEqual(done["reason"], "length")

    def test_load_needs_a_model_name(self):
        with self.assertRaises(urllib.error.HTTPError) as caught:
            self.request("/load", {})
        self.assertEqual(caught.exception.code, 400)

    def test_unknown_route(self):
        with self.assertRaises(urllib.error.HTTPError) as caught:
            self.request("/nope", {})
        self.assertEqual(caught.exception.code, 404)


if __name__ == "__main__":
    unittest.main()
