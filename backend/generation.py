"""Generating a reply with AirLLM and reporting progress as events."""

import time

from airllm_hooks import Cancelled
from prompting import TextStreamer, build_prompt, stop_token_ids


def generate(state, hooks, messages, max_new_tokens, temperature, emit):
    """Streams one reply through emit(event_dict).

    Events: progress (layer by layer), token (text delta), and a final done event
    with timing so the app can measure this Mac's real speed.
    """
    import mlx.core as mx

    model = state.model
    tokenizer = model.tokenizer
    prompt = build_prompt(tokenizer, messages)
    # Chat templates already add BOS, so only add special tokens for the plain layout.
    has_template = bool(getattr(tokenizer, "chat_template", None))
    ids = tokenizer(prompt, return_tensors="np", add_special_tokens=not has_template)["input_ids"]
    stops = stop_token_ids(tokenizer, getattr(model, "config", None))
    streamer = TextStreamer(tokenizer)

    start = time.time()
    first_token_at = None
    reason = "length"

    def on_progress(layer, total):
        phase = "prompt" if not streamer.tokens else "token"
        emit({"type": "progress", "phase": phase, "token_index": len(streamer.tokens),
              "layer": layer, "total": total})

    hooks.on_progress = on_progress
    hooks.temperature = float(temperature)
    try:
        for y in model.model_generate(mx.array(ids), temperature=temperature):
            token = int(y.item())
            first_token_at = first_token_at or time.time()
            if token in stops:
                reason = "eos"
                break
            delta = streamer.add(token)
            if delta:
                emit({"type": "token", "text": delta})
            if len(streamer.tokens) >= max_new_tokens:
                break
            if state.cancel.is_set():
                reason = "stopped"
                break
    except Cancelled:
        reason = "stopped"
    finally:
        hooks.on_progress = None

    emit({
        "type": "done",
        "reason": reason,
        "tokens": len(streamer.tokens),
        "prompt_tokens": int(ids.shape[1]),
        "seconds": time.time() - start,
        "time_to_first_token": (first_token_at - start) if first_token_at else None,
    })
