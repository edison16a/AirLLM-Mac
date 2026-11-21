import unittest
from types import SimpleNamespace

import helpers  # noqa: F401  (puts backend/ on the path)
import prompting


class FakeTokenizer:
    """Maps ids to fixed strings, with id 9 being half of a multi-byte character."""

    pieces = {1: "Hel", 2: "lo", 3: " wor", 4: "ld", 9: "�"}

    def __init__(self, template=None, eos=2):
        self.chat_template = template
        self.eos_token_id = eos

    def decode(self, ids, skip_special_tokens=True):
        return "".join(self.pieces[i] for i in ids)

    def apply_chat_template(self, messages, tokenize=False, add_generation_prompt=True):
        return "TEMPLATE:" + "|".join(m["content"] for m in messages)


class BuildPromptTests(unittest.TestCase):
    messages = [
        {"role": "system", "content": "Be brief."},
        {"role": "user", "content": " Hi "},
        {"role": "assistant", "content": "Hello"},
        {"role": "user", "content": "Why?"},
    ]

    def test_uses_the_models_template(self):
        prompt = prompting.build_prompt(FakeTokenizer(template="x"), self.messages)
        self.assertEqual(prompt, "TEMPLATE:Be brief.| Hi |Hello|Why?")

    def test_falls_back_to_plain_layout(self):
        prompt = prompting.build_prompt(FakeTokenizer(), self.messages)
        self.assertTrue(prompt.startswith("Be brief.\n"))
        self.assertIn("### User:\nHi\n", prompt)
        self.assertTrue(prompt.endswith("### Assistant:\n"))


class StopTokenTests(unittest.TestCase):
    def test_merges_tokenizer_and_config_ids(self):
        ids = prompting.stop_token_ids(FakeTokenizer(eos=2), SimpleNamespace(eos_token_id=[2, 7, 8]))
        self.assertEqual(ids, {2, 7, 8})

    def test_handles_a_single_config_id(self):
        ids = prompting.stop_token_ids(FakeTokenizer(eos=None), SimpleNamespace(eos_token_id=5))
        self.assertEqual(ids, {5})


class TextStreamerTests(unittest.TestCase):
    def test_sends_only_new_text(self):
        streamer = prompting.TextStreamer(FakeTokenizer())
        self.assertEqual([streamer.add(i) for i in (1, 2, 3, 4)], ["Hel", "lo", " wor", "ld"])

    def test_waits_for_the_rest_of_a_character(self):
        streamer = prompting.TextStreamer(FakeTokenizer())
        streamer.add(1)
        self.assertEqual(streamer.add(9), "")


if __name__ == "__main__":
    unittest.main()
