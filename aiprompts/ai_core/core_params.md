# how to use params

works very well in combination with heroscript

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

### Advanced

```v
get_map() map[string]string

get_path(key string) !string

get_path_create(key string) !string //will create path if it doesnt exist yet

get_percentage(key string) !f64

get_percentage_default(key string, defval string) !f64

//convert GB, MB, KB to bytes e.g. 10 GB becomes bytes in u64
get_storagecapacity_in_bytes(key string) !u64

get_storagecapacity_in_bytes_default(key string, defval u64) !u64

get_storagecapacity_in_gigabytes(key string) !u64

//Get Expiration object from time string input input can be either relative or absolute## Relative time
get_time(key string) !ourtime.OurTime

get_time_default(key string, defval ourtime.OurTime) !ourtime.OurTime

get_time_interval(key string) !Duration

get_timestamp(key string) !Duration

get_timestamp_default(key string, defval Duration) !Duration

```