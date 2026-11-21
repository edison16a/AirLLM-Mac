"""Turning chat messages into a prompt, and model tokens back into text."""


def build_prompt(tokenizer, messages):
    """Uses the model's own chat template when it has one.

    Base models without a template get a plain "### User / ### Assistant" layout,
    which most instruction-tuned Llama derivatives follow well enough.
    """
    if getattr(tokenizer, "chat_template", None):
        try:
            return tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
        except Exception:
            pass
    parts = []
    for m in messages:
        text = m["content"].strip()
        if m["role"] == "system":
            parts.append(text + "\n")
        elif m["role"] == "user":
            parts.append(f"### User:\n{text}\n")
        else:
            parts.append(f"### Assistant:\n{text}\n")
    parts.append("### Assistant:\n")
    return "\n".join(parts)


def stop_token_ids(tokenizer, config):
    """Every id that means "end of reply". Llama 3 lists several in its config."""
    ids = set()
    if tokenizer.eos_token_id is not None:
        ids.add(int(tokenizer.eos_token_id))
    config_eos = getattr(config, "eos_token_id", None)
    if isinstance(config_eos, int):
        ids.add(config_eos)
    elif isinstance(config_eos, (list, tuple)):
        ids.update(int(x) for x in config_eos)
    return ids


class TextStreamer:
    """Turns a growing list of token ids into text deltas.

    Decoding one token at a time breaks words that span tokens and multi-byte
    characters, so this decodes everything so far and sends only what's new.
    """

    def __init__(self, tokenizer):
        self.tokenizer = tokenizer
        self.tokens = []
        self.sent = ""

    def add(self, token_id):
        """Returns the new text, or "" when nothing printable has arrived yet."""
        self.tokens.append(token_id)
        text = self.tokenizer.decode(self.tokens, skip_special_tokens=True)
        if text.endswith("�"):  # half of a multi-byte character, wait for the rest
            return ""
        delta = text[len(self.sent):] if text.startswith(self.sent) else text
        self.sent = text
        return delta
