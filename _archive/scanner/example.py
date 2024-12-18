import os
import sys


def load_example() -> str:
    # Start from the current working directory
    current_dir = os.path.dirname(os.path.abspath(__file__))

    examples_dir = os.path.join(current_dir, "examples")

    examples = ""
    if os.path.isdir(examples_dir):
        examples = load_v_files(examples_dir)

    return examples


def load_v_files(path: str) -> str:
    examples = ""
    for entry in os.listdir(path):
        if os.path.isdir(entry):
            examples += load_v_files(entry) + "\n\n"
        elif entry.endswith(".v"):
            with open(entry, "r") as file:
                examples += file.read() + "\n"

    return examples
