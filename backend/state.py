"""Shared server state: the loaded model, what it's doing, and the stop flag."""

import threading


class ServerState:
    """One model at a time, one generation at a time.

    AirLLM streams the whole model from disk for every token, so two generations at
    once would just fight over the disk. The lock makes the second request fail fast.
    """

    def __init__(self, mock=False):
        self.mock = mock
        self.model = None
        self.model_id = None
        self.n_layers = None
        self.loading_model = None
        self.error = None
        self.generating = False
        self.lock = threading.Lock()
        self.generation_lock = threading.Lock()
        self.cancel = threading.Event()

    def snapshot(self):
        with self.lock:
            return {
                "model_id": self.model_id,
                "loading": self.loading_model is not None,
                "loading_model": self.loading_model,
                "error": self.error,
                "generating": self.generating,
                "n_layers": self.n_layers,
                "mock": self.mock,
            }

    def begin_loading(self, model_id):
        """Returns an error message if a load can't start right now."""
        with self.lock:
            if self.loading_model:
                return "a model is already loading"
            if self.generating:
                return "a reply is being generated"
            self.loading_model = model_id
            self.error = None
        return None

    def finish_loading(self, model=None, model_id=None, n_layers=None, error=None):
        with self.lock:
            if error is None:
                self.model, self.model_id, self.n_layers = model, model_id, n_layers
            self.loading_model = None
            self.error = error

    def unload(self):
        with self.lock:
            self.model = None
            self.model_id = None
            self.n_layers = None
