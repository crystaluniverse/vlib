# HJSON Module

A V module for handling JSON data with additional utility functions for filtering, extracting, and manipulating JSON structures.

## Features

- JSON list splitting
- JSON dictionary filtering and extraction
- Clean ASCII handling option
- Support for both string and Any type outputs

## Main Functions

### `json_list(r string, clean bool) []string`
Splits a list of dictionaries into text blocks. Useful for processing large JSON arrays of objects.

### `json_dict_get_any(r string, clean bool, key string) !json2.Any`
Extracts a value from a JSON dictionary by key, returning it as `json2.Any`.

### `json_dict_get_string(r string, clean bool, key string) !string`
Similar to `json_dict_get_any` but returns the result as a string.

### `json_dict_filter_any(r string, clean bool, include []string, exclude []string) !map[string]json2.Any`
Filters a JSON dictionary based on included and excluded keys.

### `json_dict_filter_string(r string, clean bool, include []string, exclude []string) !map[string]string`
Similar to `json_dict_filter_any` but returns a map of strings.

### `json_list_dict_get_any(r string, clean bool, key string) ![]json2.Any`
Processes a list of dictionaries and extracts values for a specific key from each dictionary.

### `json_list_dict_get_string(r string, clean bool, key string) ![]string`
Similar to `json_list_dict_get_any` but returns an array of strings.

## Usage Examples

```v
// Get a value from a JSON dictionary
json_str := '{"name": "John", "age": 30}'
name := json_dict_get_string(json_str, true, "name")!
println(name) // Output: "John"

// Filter JSON dictionary
json_str := '{"name": "John", "age": 30, "city": "New York"}'
include := ["name", "age"]
exclude := []
filtered := json_dict_filter_string(json_str, true, include, exclude)!
println(filtered) // Output: {"name": "John", "age": 30}

// Process a list of dictionaries
json_list := '[{"user": {"name": "John"}}, {"user": {"name": "Jane"}}]'
names := json_list_dict_get_string(json_list, true, "user")!
println(names) // Output: [{"name": "John"}, {"name": "Jane"}]
```

## Parameters

- `r string`: The input JSON string to process
- `clean bool`: When true, cleans the input string to ensure ASCII compatibility
- `key string`: The key to search for in JSON dictionaries
- `include []string`: List of keys to include in filtered output
- `exclude []string`: List of keys to exclude from filtered output

## Error Handling

All functions that can fail return a Result type (`!`). Common error cases include:
- Empty input strings
- Invalid JSON format
- Missing keys
- Invalid data types
