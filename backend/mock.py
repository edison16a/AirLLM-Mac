"""Demo mode: fake replies that exercise streaming, progress and Stop with no model."""

import time

REPLY = (
    "This is **demo mode**. No model is loaded, but streaming, the progress bar and the "
    "stop button all work.\n\n- one\n- two\n- three\n\nAnd some `inline code`."
)


def generate(state, messages, max_new_tokens, emit, layers=32):
    start = time.time()
    words = REPLY.split(" ")
    prompt_tokens = sum(len(m["content"].split()) for m in messages)
    count = min(len(words), max_new_tokens)
    reason = "eos" if count == len(words) else "length"

    for t in range(count):
        for layer in range(0, layers + 1, 8):
            if state.cancel.is_set():
                reason, count = "stopped", t
                break
            emit({"type": "progress", "phase": "prompt" if t == 0 else "token",
                  "token_index": t, "layer": layer, "total": layers})
            time.sleep(0.01)
        if reason == "stopped":
            break
        emit({"type": "token", "text": words[t] + (" " if t < len(words) - 1 else "")})

    emit({"type": "done", "reason": reason, "tokens": count, "prompt_tokens": prompt_tokens,
          "seconds": time.time() - start, "time_to_first_token": 0.05})
