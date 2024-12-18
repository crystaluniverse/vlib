# TextTools Module

The TextTools module provides a comprehensive set of utilities for text manipulation and processing in V. It includes functions for cleaning, parsing, formatting, and transforming text in various ways.

## Features

### Array Operations
- `to_array(r string) []string` - Converts a comma or newline separated list to an array of strings
- `to_array_int(r string) []int` - Converts a text list to an array of integers
- `to_map(mapstring string, line string, delimiter_ string) map[string]string` - Intelligent mapping of a line to a map based on a template

### Text Cleaning
- `name_clean(r string) string` - Normalizes names by removing special characters
- `ascii_clean(r string) string` - Removes all non-ASCII characters
- `remove_empty_lines(text string) string` - Removes empty lines from text
- `remove_double_lines(text string) string` - Removes consecutive empty lines
- `remove_empty_js_blocks(text string) string` - Removes empty code blocks (```...```)

### Command Line Parsing
- `cmd_line_args_parser(text string) ![]string` - Parses command line arguments with support for quotes and escaping
- `text_remove_quotes(text string) string` - Removes quoted sections from text
- `check_exists_outside_quotes(text string, items []string) bool` - Checks if items exist in text outside of quotes

### Text Expansion
- `expand(txt_ string, l int, expand_with string) string` - Expands text to a specified length with a given character

### Indentation
- `indent(text string, prefix string) string` - Adds indentation prefix to each line
- `dedent(text string) string` - Removes common leading whitespace from every line

### String Validation
- `is_int(text string) bool` - Checks if text contains only digits
- `is_upper_text(text string) bool` - Checks if text contains only uppercase letters

### Multiline Processing
- `multiline_to_single(text string) !string` - Converts multiline text to a single line with proper escaping
- Handles comments, code blocks, and preserves formatting

### Name/Path Processing
- `name_fix(name string) string` - Normalizes filenames and paths
- `name_fix_keepspace(name string) !string` - Like name_fix but preserves spaces
- `name_fix_no_ext(name_ string) string` - Removes file extension
- `name_fix_snake_to_pascal(name string) string` - Converts snake_case to PascalCase
- `name_fix_pascal_to_snake(name string) string` - Converts PascalCase to snake_case
- `name_split(name string) !(string, string)` - Splits name into site and page components

### Text Splitting
- `split_smart(t string, delimiter_ string) []string` - Intelligent string splitting that respects quotes

### Tokenization
- `tokenize(text_ string) TokenizerResult` - Tokenizes text into meaningful parts
- `text_token_replace(text string, tofind string, replacewith string) !string` - Replaces tokens in text

### Version Parsing
- `version(text_ string) int` - Converts version strings to comparable integers
  - Example: "v0.4.36" becomes 4036
  - Example: "v1.4.36" becomes 1004036

## Usage Examples

### Array Operations
```v
// Convert comma-separated list to array
text := "item1,item2,item3"
array := texttools.to_array(text)
// Result: ['item1', 'item2', 'item3']

// Smart mapping
r := texttools.to_map("name,-,-,-,-,pid,-,-,-,-,path",
    "root   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 /usr/sbin/distnoted")
// Result: {'name': 'root', 'pid': '1360', 'path': '/usr/sbin/distnoted'}
```

### Text Cleaning
```v
// Clean name
name := texttools.name_clean("Hello@World!")
// Result: "HelloWorld"

// Remove empty lines
text := texttools.remove_empty_lines("line1\n\nline2\n\n\nline3")
// Result: "line1\nline2\nline3"
```

### Command Line Parsing
```v
// Parse command line with quotes
args := texttools.cmd_line_args_parser("'arg with spaces' --flag=value")
// Result: ['arg with spaces', '--flag=value']
```

### Indentation
```v
// Add indentation
text := texttools.indent("line1\nline2", "  ")
// Result: "  line1\n  line2\n"

// Remove common indentation
text := texttools.dedent("    line1\n    line2")
// Result: "line1\nline2"
```

### Name Processing
```v
// Convert to snake case
name := texttools.name_fix_pascal_to_snake("HelloWorld")
// Result: "hello_world"

// Convert to pascal case
name := texttools.name_fix_snake_to_pascal("hello_world")
// Result: "HelloWorld"
```

### Version Parsing
```v
// Parse version string
ver := texttools.version("v0.4.36")
// Result: 4036

ver := texttools.version("v1.4.36")
// Result: 1004036
```

## Error Handling

Many functions in the module return a Result type (indicated by `!` in the function signature). These functions can return errors that should be handled appropriately:

```v
// Example of error handling
name := texttools.name_fix_keepspace("some@name") or {
    println("Error: ${err}")
    return
}
```

## Best Practices

1. Always use appropriate error handling for functions that return Results
2. Consider using `dedent()` before processing multiline text to ensure consistent formatting
3. When working with filenames, use the appropriate name_fix variant based on your needs
4. For command line parsing, be aware of quote handling and escaping rules
5. When using tokenization, consider the context and whether smart splitting is needed

## Contributing

The TextTools module is part of the CrystalLib project. Contributions are welcome through pull requests.
