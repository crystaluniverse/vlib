import re
import os


# remoces pub, mut, non needed code, ...
def cleaner(code: str):
    lines = code.split("\n")
    processed_lines = []
    in_function = False
    in_struct_or_enum = False

    for line in lines:
        line = line.replace("\t", "    ")
        stripped_line = line.strip()

        # Skip lines starting with 'pub mut:'
        if re.match(r"^\s*pub\s*(\s+mut\s*)?:", stripped_line):
            continue

        # Remove 'pub ' at the start of struct and function lines
        if stripped_line.startswith("pub "):
            line = line.lstrip()[4:]  # Remove leading spaces and 'pub '

        # Check if we're entering or exiting a struct or enum
        if re.match(r"(struct|enum)\s+\w+\s*{", stripped_line):
            in_struct_or_enum = True
            processed_lines.append(line)
        elif in_struct_or_enum and "}" in stripped_line:
            in_struct_or_enum = False
            processed_lines.append(line)
        elif in_struct_or_enum:
            # Ensure consistent indentation within structs and enums
            processed_lines.append(line)
        else:
            # Handle function declarations
            if "fn " in stripped_line:
                if "{" in stripped_line:
                    # Function declaration and opening brace on the same line
                    in_function = True
                    processed_lines.append(line)
                else:
                    return Exception(f"accolade needs to be in fn line.\n{line}")
            elif in_function:
                if stripped_line == "}":
                    # Closing brace of the function
                    in_function = False
                    processed_lines.append("}")
                # Skip all other lines inside the function
            else:
                processed_lines.append(line)

    return "\n".join(processed_lines)


def load(path: str) -> str:
    # walk over directory find all .v files, recursive
    # ignore all imports (import at start of line)
    # ignore all module ... (module at start of line)
    path = os.path.expanduser(path)
    if not os.path.exists(path):
        raise FileNotFoundError(f"The path '{path}' does not exist.")
    all_code = []
    # Walk over directory recursively
    for root, _, files in os.walk(path):
        for file in files:
            if file.endswith(".v"):
                file_path = os.path.join(root, file)
                with open(file_path, "r") as f:
                    lines = f.readlines()

                # Filter out import and module lines
                filtered_lines = [
                    line
                    for line in lines
                    if not line.strip().startswith(("import", "module"))
                ]

                all_code.append("".join(filtered_lines))

    return "\n\n".join(all_code)


if __name__ == "__main__":
    # from hero_server.lib.openrpc.parser.example import load_example
    code = load("~/code/git.ourworld.tf/projectmycelium/hero_server/lib/openrpclib/parser/examples")
    # Parse the code
    code = cleaner(code)
    print(code)
