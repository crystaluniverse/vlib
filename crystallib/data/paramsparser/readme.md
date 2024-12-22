# ParamsParser Module Documentation

The ParamsParser module provides a powerful way to parse and handle parameter strings in V. 
It's particularly useful for parsing command-line style arguments and key-value pairs from text.

## How to get the paramsparser

```v
import freeflowuniverse.crystallib.data.paramsparser

// Create new params from text
params := paramsparser.new("color:red size:'large' priority:1 enable:true")!

// Or create empty params and add later
mut params := paramsparser.new_params()
params.set("color", "red")
```

## Parameter Format

The parser supports several formats:

1. Key-value pairs: `key:value`
2. Quoted values: `key:'value with spaces'`
3. Arguments without keys: `arg1 arg2`
4. Comments: `// this is a comment`

Example:
```v
text := "name:'John Doe' age:30 active:true // user details"
params := paramsparser.new(text)!
```

## Getting Values

The module provides various methods to retrieve values:

```v
// Get string value
name := params.get("name")! // returns "John Doe"

// Get with default value
color := params.get_default("color", "blue")! // returns "blue" if color not set

// Get as integer
age := params.get_int("age")! // returns 30

// Get as boolean (true if value is "1", "true", "y", "yes")
is_active := params.get_default_true("active")

// Get as float
score := params.get_float("score")!

// Get as percentage (converts "80%" to 0.8)
progress := params.get_percentage("progress")!
```

## Type Conversion Methods

The module supports various type conversions:

### Basic Types
- `get_int()`: Convert to int32
- `get_u32()`: Convert to unsigned 32-bit integer
- `get_u64()`: Convert to unsigned 64-bit integer
- `get_u8()`: Convert to unsigned 8-bit integer
- `get_float()`: Convert to 64-bit float
- `get_percentage()`: Convert percentage string to float (e.g., "80%" → 0.8)

### Boolean Values
- `get_default_true()`: Returns true if value is empty, "1", "true", "y", or "yes"
- `get_default_false()`: Returns false if value is empty, "0", "false", "n", or "no"

### Lists
The module provides robust support for parsing and converting lists:

```v
// Basic list parsing
names := params.get_list("users")! // parses ["user1", "user2", "user3"]

// With default value
tags := params.get_list_default("tags", ["default"])!

// Lists with type conversion
numbers := params.get_list_int("ids")! // converts each item to int
amounts := params.get_list_f64("prices")! // converts each item to f64

// Name-fixed lists (normalizes each item)
clean_names := params.get_list_namefix("categories")!
```

Supported list types:
- `get_list()`: String list
- `get_list_u8()`, `get_list_u16()`, `get_list_u32()`, `get_list_u64()`: Unsigned integers
- `get_list_i8()`, `get_list_i16()`, `get_list_int()`, `get_list_i64()`: Signed integers
- `get_list_f32()`, `get_list_f64()`: Floating point numbers

Each list method has a corresponding `_default` version that accepts a default value.

Valid list formats:
```v
users: "john, jane,bob"
ids: "1,2,3,4,5"
```

## Working with Arguments

Arguments are values without keys:

```v
// Parse text with arguments
params := paramsparser.new("arg1 arg2 key:value")!

// Add an argument
params.set_arg("arg3")

// Check if argument exists
if params.exists_arg("arg1") {
    // do something
}
```

## Additional Features

1. Case insensitive keys:
```v
params.set("Color", "red")
value := params.get("color")! // works
```

2. Map conversion:
```v
// Convert params to map
map_values := params.get_map()
```

3. Merging params:
```v
mut params1 := paramsparser.new("color:red")!
params2 := paramsparser.new("size:large")!
params1.merge(params2)!
```

4. Delete parameters:
```v
params.delete("color") // delete key-value pair
params.delete_arg("arg1") // delete argument
```

## Error Handling

Most methods return results that should be handled with V's error handling:

```v
// Using ! operator for methods that can fail
name := params.get("name")!

// Or with or {} block for custom error handling
name := params.get("name") or {
    println("Error: ${err}")
    "default_name"
}
```

## Parameter Validation

The parser enforces certain rules:
- Keys can only contain A-Z, a-z, 0-9, underscore, dot, and forward slash
- Values can contain any characters
- Spaces in values must be enclosed in quotes
- Lists are supported with comma separation

## Best Practices

1. Always handle potential errors with `!` or `or {}`
2. Use type-specific getters (`get_int`, `get_float`, etc.) when you know the expected type
3. Provide default values when appropriate using the `_default` methods
4. Use quotes for values containing spaces
5. Use lowercase keys for consistency (though the parser is case-insensitive)


# Params Details

```v
import freeflowuniverse.crystallib.data.paramsparser

mut p:=paramsparser.new('
    id:a1 name6:aaaaa
    name:'need to do something 1' 
)!

assert "a1"==p.get_default("id","")!


```

example text to parse

```yaml
id:a1 name6:aaaaa
name:'need to do something 1' 
description:
    ## markdown works in it

    description can be multiline
    lets see what happens

    - a
    - something else

    ### subtitle


name2:   test
name3: hi name10:'this is with space'  name11:aaa11

#some comment

name4: 'aaa'

//somecomment
name5:   'aab' 
```

results in

```go
Params{
    params: [Param{
        key: 'id'
        value: 'a1'
    }, Param{
        key: 'name6'
        value: 'aaaaa'
    }, Param{
        key: 'name'
        value: 'need to do something 1'
    }, Param{
        key: 'description'
        value: '## markdown works in it

                description can be multiline
                lets see what happens
                
                - a
                - something else
                
                ### subtitle
                '
		}, Param{
			key: 'name2'
			value: 'test'
		}, Param{
			key: 'name3'
			value: 'hi'
		}, Param{
			key: 'name10'
			value: 'this is with space'
		}, Param{
			key: 'name11'
			value: 'aaa11'
		}, Param{
			key: 'name4'
			value: 'aaa'
		}, Param{
			key: 'name5'
			value: 'aab'
		}]
	}
```

