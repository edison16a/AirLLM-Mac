"""Keeps the last lines of output so the app can show what AirLLM is doing.

AirLLM reports download and splitting progress with print() and tqdm, not a callback.
Copying stdout and stderr into a ring buffer is the only way to surface it.
"""

import collections
import io
import sys
import threading

_lines = collections.deque(maxlen=200)
_lock = threading.Lock()


class _Tee(io.TextIOBase):
    """Writes through to the real stream and records complete lines."""

    def __init__(self, stream):
        self.stream = stream
        self.pending = ""

    def write(self, s):
        try:
            self.stream.write(s)
            self.stream.flush()
        except Exception:
            pass
        self.pending += s
        # tqdm redraws one line with \r, so treat it as a line break.
        parts = self.pending.replace("\r", "\n").split("\n")
        self.pending = parts.pop()
        with _lock:
            _lines.extend(p.strip() for p in parts if p.strip())
        return len(s)

    def flush(self):
        try:
            self.stream.flush()
        except Exception:
            pass


def install():
    sys.stdout = _Tee(sys.__stdout__)
    sys.stderr = _Tee(sys.__stderr__)


def recent(n=40):
    with _lock:
        return list(_lines)[-n:]


def log(message):
    print(f"[airllm-chat] {message}")
