import unittest

import helpers  # noqa: F401  (puts backend/ on the path)
from state import ServerState


class ServerStateTests(unittest.TestCase):
    def test_one_load_at_a_time(self):
        state = ServerState()
        self.assertIsNone(state.begin_loading("a"))
        self.assertEqual(state.begin_loading("b"), "a model is already loading")
        self.assertEqual(state.snapshot()["loading_model"], "a")

    def test_no_load_while_generating(self):
        state = ServerState()
        state.generating = True
        self.assertEqual(state.begin_loading("a"), "a reply is being generated")

    def test_finish_loading_sets_the_model(self):
        state = ServerState()
        state.begin_loading("a")
        state.finish_loading(model=object(), model_id="a", n_layers=22)
        snapshot = state.snapshot()
        self.assertEqual((snapshot["model_id"], snapshot["n_layers"], snapshot["loading"]), ("a", 22, False))

    def test_failed_load_keeps_the_old_model(self):
        state = ServerState()
        state.begin_loading("a")
        state.finish_loading(model=object(), model_id="a", n_layers=22)
        state.begin_loading("b")
        state.finish_loading(error="download failed")
        snapshot = state.snapshot()
        self.assertEqual(snapshot["model_id"], "a")
        self.assertEqual(snapshot["error"], "download failed")

    def test_unload(self):
        state = ServerState()
        state.finish_loading(model=object(), model_id="a", n_layers=1)
        state.unload()
        self.assertIsNone(state.snapshot()["model_id"])


if __name__ == "__main__":
    unittest.main()
