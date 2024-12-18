import re
import json
from enum import Enum
from hero_server.lib.openrpc.parser.cleaner import cleaner


class CodeType(Enum):
    STRUCT = "struct"
    ENUM = "enum"
    FUNCTION = "function"


def splitter(code: str):
    lines = code.split("\n")
    result = []
    current_block = None
    current_comments = []

    for line in lines:
        line = line.replace("\t", "    ")
        stripped_line = line.strip()

        if stripped_line.startswith("//"):
            current_comments.append(stripped_line[2:].strip())
        elif stripped_line.startswith("struct "):
            if current_block:
                result.append(current_block)
            current_block = {
                "type": CodeType.STRUCT,
                "comments": current_comments,
                "block": line,
            }
            current_comments = []
        elif stripped_line.startswith("enum "):
            if current_block:
                result.append(current_block)
            current_block = {
                "type": CodeType.ENUM,
                "comments": current_comments,
                "block": line,
            }
            current_comments = []
        elif stripped_line.startswith("fn "):
            if current_block:
                result.append(current_block)
            current_block = {
                "type": CodeType.FUNCTION,
                "comments": current_comments,
                "block": line.split("{")[0].strip(),
            }
            current_comments = []
        elif current_block:
            if current_block["type"] == CodeType.STRUCT and stripped_line == "}":
                current_block["block"] += "\n" + line
                result.append(current_block)
                current_block = None
            elif current_block["type"] == CodeType.ENUM and stripped_line == "}":
                current_block["block"] += "\n" + line
                result.append(current_block)
                current_block = None
            elif current_block["type"] in [CodeType.STRUCT, CodeType.ENUM]:
                current_block["block"] += "\n" + line

    if current_block:
        result.append(current_block)

    return result


if __name__ == "__main__":
    from hero_server.lib.openrpc.parser.cleaner import load

    code = load(
        "/root/code/git.ourworld.tf/projectmycelium/hero_server/lib/openrpclib/parser/examples"
    )
    code = cleaner(code)
    # Test the function
    parsed_code = splitter(code)
    for item in parsed_code:
        print(f"Type: {item['type']}")
        print(f"Comments: {item['comments']}")
        print(f"Block:\n{item['block']}")
        print("-" * 50)
