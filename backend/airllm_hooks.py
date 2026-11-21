"""Small patches to AirLLM's MLX module that the app depends on.

AirLLM's macOS path has no progress callback, ignores temperature, and can't be
interrupted. It does wrap its layer loop in tqdm and call a module-level sample(), so
replacing those two names gives us all three features without forking AirLLM.
"""


class Cancelled(Exception):
    """Raised inside AirLLM's layer loop when the user presses Stop."""


class Hooks:
    def __init__(self, cancel_event):
        self.cancel = cancel_event
        self.on_progress = None  # callable(layer_index, total) while generating
        self.temperature = 0.0
        self._installed = False

    def install(self):
        if self._installed:
            return
        import airllm.airllm_llama_mlx as mlx_module

        real_sample = mlx_module.sample

        def sample(logits, temperature=0):
            # model_generate() never passes temperature through, so use ours.
            return real_sample(logits, temperature=self.temperature)

        def layer_loop(iterable, desc=None, **kwargs):
            items = list(iterable)
            for i, item in enumerate(items):
                if self.cancel.is_set():
                    raise Cancelled()
                if self.on_progress:
                    self.on_progress(i, len(items))
                yield item
            if self.on_progress:
                self.on_progress(len(items), len(items))

        mlx_module.sample = sample
        mlx_module.tqdm = layer_loop
        self._installed = True
