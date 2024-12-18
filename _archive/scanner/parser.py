import re
import json
import yaml
from hero_server.lib.openrpc.parser.example import load_example
from hero_server.lib.openrpc.parser.cleaner import cleaner, load
from hero_server.lib.openrpc.parser.splitter import splitter, CodeType
from typing import List, Tuple
from hero_server.lib.openrpc.parser.includes import *

# use https://regex101.com/


def parse_field_description(field_description):
    # Initialize the result dictionary
    result = {"description": "", "index": False, "example": None}

    # Check if the field is indexed
    if field_description.strip().endswith("*"):
        result["index"] = True
        field_description = field_description.strip()[:-1].strip()

    # Split the description and example
    parts = field_description.split("example=", 1)

    # Set the description
    result["description"] = parts[0].strip()

    # Extract the example if it exists
    if len(parts) > 1:
        example_value = parts[1].strip()
        if example_value.startswith("[") and example_value.endswith("]"):
            result["example"] = json.loads(example_value)
        elif example_value.isdigit():
            result["example"] = int(example_value)
        else:
            example_match = re.search(r'["\'](.+?)["\']', example_value)
            if example_match:
                result["example"] = example_match.group(1)

    return result


def parse_struct(struct_def):
    struct_name = re.search(r"struct (\w+)", struct_def).group(1)
    fields = re.findall(r"\s+(\w+)\s+([\w\[\]]+)(?:\s*\/\/(.+))?", struct_def)
    return struct_name, fields


def parse_enum(enum_def):
    enum_name = re.search(r"enum (\w+)", enum_def).group(1)
    values = re.findall(r"\n\s+(\w+)", enum_def)
    return enum_name, values


def parse_function(func_def):
    # Match the function signature
    match = re.search(r"fn (\w+)\((.*?)\)\s*(!?\w*)", func_def)
    if match:
        func_name = match.group(1)
        params_str = match.group(2).strip()
        return_type = match.group(3).strip()

        if return_type.startswith("RO_"):
            return_type = return_type[3:]
        if return_type.startswith("!RO_"):
            return_type = return_type[4:]
        if return_type.startswith("?RO_"):
            return_type = return_type[4:]

        # print(f" -- return type: {return_type}")

        # Parse parameters
        params = []
        if params_str:
            # This regex handles parameters with or without type annotations
            param_pattern = re.compile(r"(\w+)(?:\s+(\w+))?")
            for param_match in param_pattern.finditer(params_str):
                param_name, param_type = param_match.groups()
                if param_type.startswith("RO_"):
                    param_type = param_type[3:]
                params.append((param_name, param_type if param_type else None))

        return func_name, params, return_type
    return None, None, None


def get_type_schema(type_name):
    if type_name.startswith("[]"):
        item_type = type_name[2:]
        return {"type": "array", "items": get_type_schema(item_type)}
    elif type_name in ["string"]:
        return {"type": "string"}
    elif type_name in ["f64", "float", "f32", "f16"]:
        return {"type": "number"}
    elif type_name in ["int"]:
        return {"type": "integer"}
    elif type_name == "bool":
        return {"type": "boolean"}
    elif type_name == "":
        return {"type": "null"}
    else:
        return {"$ref": f"#/components/schemas/{type_name}"}


def parser(code: str = "", path: str = "") -> dict:
    if len(code) > 0 and len(path) > 0:
        raise Exception("cannot have code and path filled in at same time")
    if len(path) > 0:
        code = load(path)
        includes_dict = include_process_directory(path)
    else:
        includes_dict = includes_process_text(path)

    openrpc_spec = {
        "openrpc": "1.2.6",
        "info": {"title": "V Code API", "version": "1.0.0"},
        "methods": [],
        "components": {"schemas": {}},
    }

    # this function just cleans the code so we have a proper input for the parser
    code = cleaner(code)

    # this function is a pre-processor, it finds include blocks and adds them in
    code = include_process_text(code, includes_dict)

    codeblocks = splitter(code)

    structs: List[Tuple[dict, List[str]]] = list()
    enums = list()
    functions = list()

    for item in codeblocks:
        if item["type"] == CodeType.STRUCT:
            structs.append((item["block"], item["comments"]))
        if item["type"] == CodeType.ENUM:
            enums.append((item["block"], item["comments"]))
        if item["type"] == CodeType.FUNCTION:
            functions.append((item["block"], item["comments"]))

    # Process structs and enums
    for item in structs:
        struct_name, fields = parse_struct(item[0])
        rootobject = False
        if struct_name.startswith("RO_"):
            rootobject = True
            struct_name = struct_name[3:]

        openrpc_spec["components"]["schemas"][struct_name] = {
            "type": "object",
            "properties": {},
        }

        for field in fields:
            field_name, field_type, field_description = field
            parsed_description = parse_field_description(field_description)

            field_schema = {
                **get_type_schema(field_type),
                "description": parsed_description["description"],
            }

            if parsed_description["example"]:
                field_schema["example"] = parsed_description["example"]

            if parsed_description["index"]:
                field_schema["x-tags"] = field_schema.get("x-tags", []) + ["indexed"]

            openrpc_spec["components"]["schemas"][struct_name]["properties"][
                field_name
            ] = field_schema

        if rootobject:
            openrpc_spec["components"]["schemas"][struct_name]["x-tags"] = [
                "rootobject"
            ]

            functions.append(
                (f"fn {struct_name.lower()}_get(id string) {struct_name}", [])
            )
            functions.append((f"fn {struct_name.lower()}_set(obj {struct_name})", []))
            functions.append((f"fn {struct_name.lower()}_delete(id string)", []))

    for item in enums:
        enum_name, values = parse_enum(item[0])
        openrpc_spec["components"]["schemas"][enum_name] = {
            "type": "string",
            "enum": values,
        }

    # print(functions)
    # from IPython import embed; embed()
    # Process functions
    for item in functions:
        func_name, params, return_type = parse_function(item[0])
        print(f'debugzooo {func_name} {params}')
        if return_type:
            return_type = return_type.lstrip("!")
        else:
            return_type = ""

        if func_name:
            descr_return = f"Result of the {func_name} function is {return_type}"
            descr_function = f"Executes the {func_name} function"
            if len(item[1]) > 0:
                if isinstance(item[1], list):
                    descr_function = "\n".join(item[1])
                else:
                    descr_function = "\n".join(str(element) for element in item[1:])
            method = {
                "name": func_name,
                "description": descr_function,
                "params": [],
                "result": {
                    "name": "result",
                    "description": descr_return,
                    "schema": get_type_schema(return_type),
                },
            }
            for param in params:
                # from IPython import embed; embed()
                if len(param) == 2:
                    param_name, param_type = param
                    method["params"].append(
                        {
                            "name": param_name,
                            "description": f"Parameter {param_name} of type {param_type}",
                            "schema": get_type_schema(param_type),
                        }
                    )
            openrpc_spec["methods"].append(method)  # do it in the openrpc model

    return openrpc_spec


if __name__ == "__main__":
    openrpc_spec = parser(
        path="~/code/git.ourworld.tf/projectmycelium/hero_server/generatorexamples/example1/specs"
    )
    out = json.dumps(openrpc_spec, indent=2)
    # print(out)

    filename = f"/tmp/openrpc_spec.json"
    # Write the spec to the file
    with open(filename, "w") as f:
        f.write(out)
    print(f"OpenRPC specification (JSON) has been written to: {filename}")

    yaml_filename = f"/tmp/openrpc_spec.yaml"
    with open(yaml_filename, "w") as f:
        yaml.dump(openrpc_spec, f, sort_keys=False)
    print(f"OpenRPC specification (YAML) has been written to: {yaml_filename}")
