"""Local AirLLM server for the AirLLM Mac app.

Routes:
  GET  /health   state, loaded model and recent log lines
  POST /load     {model, hf_token?, ...} starts loading in the background
  POST /chat     {messages, max_new_tokens, temperature} streams NDJSON events
  POST /stop     stops the reply in progress
  POST /unload   frees the model

Set AIRLLM_CHAT_MOCK=1 for demo mode, which fakes replies without a model.
"""

import argparse
import os
import sys
import threading
import time
from http.server import ThreadingHTTPServer

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import logcapture  # noqa: E402
from airllm_hooks import Hooks  # noqa: E402
from http_handler import make_handler  # noqa: E402
from state import ServerState  # noqa: E402


def exit_with_parent(parent_pid):
    """Quits when the app does, even if the app crashed and couldn't clean up."""

    def watch():
        while True:
            time.sleep(2)
            try:
                os.kill(parent_pid, 0)
            except OSError:
                os._exit(0)

    threading.Thread(target=watch, daemon=True).start()


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--parent-pid", type=int, default=0)
    args = parser.parse_args()

    logcapture.install()
    if args.parent_pid:
        exit_with_parent(args.parent_pid)

    state = ServerState(mock=os.environ.get("AIRLLM_CHAT_MOCK") == "1")
    handler = make_handler(state, Hooks(state.cancel))
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    logcapture.log(f"Listening on 127.0.0.1:{args.port}{' in demo mode' if state.mock else ''}")
    server.serve_forever()


if __name__ == "__main__":
    main()
