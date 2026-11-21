"""Loading a model in the background so the server stays responsive."""

import time
import traceback

from logcapture import log

MOCK_LAYERS = 32


def load(state, hooks, model_id, hf_token=None, options=None):
    """Loads model_id into state. Meant to run on its own thread.

    The first load of a model downloads it and splits it into one file per layer,
    which can take a long time. Progress shows up in the log, not here.
    """
    try:
        log(f"Loading {model_id}. The first load downloads and splits the model, which takes a while.")
        if state.mock:
            for step in range(5):
                time.sleep(0.4)
                log(f"Demo load step {step + 1} of 5")
            state.finish_loading(model="mock", model_id=model_id, n_layers=MOCK_LAYERS)
        else:
            from airllm import AutoModel

            hooks.install()
            kwargs = dict(options or {})
            if hf_token:
                kwargs["hf_token"] = hf_token
            model = AutoModel.from_pretrained(model_id, **kwargs)
            state.finish_loading(model=model, model_id=model_id, n_layers=model.model_args.n_layers)
        log(f"Ready: {model_id}")
    except Exception as e:
        traceback.print_exc()
        state.finish_loading(error=f"{type(e).__name__}: {e}")


def load_options(body):
    """Picks the AirLLM keyword arguments the app is allowed to set from a /load request."""
    import os

    options = {}
    if body.get("layer_shards_saving_path"):
        options["layer_shards_saving_path"] = os.path.expanduser(body["layer_shards_saving_path"])
    if body.get("delete_original"):
        options["delete_original"] = True
    if body.get("show_memory_util"):
        options["show_memory_util"] = True
    return options
