# V Binary Encoder/Decoder

A high-performance binary encoder/decoder module for V that provides efficient serialization and deserialization of data structures. The encoder supports automatic encoding/decoding of structs using V's compile-time reflection capabilities.

## Features

- Automatic struct encoding/decoding using compile-time reflection
- Support for primitive types, arrays, maps, and nested structs
- Compact binary format with length prefixing
- Size limits to prevent memory issues (64KB for strings/lists)
- Comprehensive error handling
- Built-in versioning support

## Supported Types

### Primitive Types
- `string`
- `int` (32-bit)
- `u8`
- `u16`
- `u32`
- `u64`
- `time.Time`

### Arrays
- `[]string`
- `[]int`
- `[]u8`
- `[]u16`
- `[]u32`
- `[]u64`

### Maps
- `map[string]string`
- `map[string][]u8`

### Structs
- Nested struct support with automatic encoding/decoding

## Usage

### Basic Encoding

```v
import freeflowuniverse.crystallib.data.encoder

// Create a new encoder
mut e := encoder.new()

// Add primitive values
e.add_string('hello')
e.add_int(42)
e.add_u8(255)
e.add_u16(65535)
e.add_u32(4294967295)
e.add_u64(18446744073709551615)

// Add arrays
e.add_list_string(['one', 'two', 'three'])
e.add_list_int([1, 2, 3])

// Add maps
e.add_map_string({
    'key1': 'value1'
    'key2': 'value2'
})

// Get encoded bytes
encoded := e.data
```

### Basic Decoding

```v
// Create decoder from bytes
mut d := encoder.decoder_new(encoded)

// Read values in same order as encoded
str := d.get_string()
num := d.get_int()
byte := d.get_u8()
u16_val := d.get_u16()
u32_val := d.get_u32()
u64_val := d.get_u64()

// Read arrays
strings := d.get_list_string()
ints := d.get_list_int()

// Read maps
str_map := d.get_map_string()
```

### Automatic Struct Encoding/Decoding

```v
struct Person {
    name string
    age  int
    tags []string
    meta map[string]string
}

// Create struct instance
person := Person{
    name: 'John'
    age: 30
    tags: ['developer', 'v']
    meta: {
        'location': 'NYC'
        'role': 'engineer'
    }
}

// Encode struct
encoded := encoder.encode(person)!

// Decode back to struct
decoded := encoder.decode[Person](encoded)!
```

## Size Limits

The encoder enforces size limits to prevent memory issues:

- Strings and lists are limited to 64KB (u16 max)
- Maps are limited to 64KB entries
- Attempting to exceed these limits will cause a panic

## Implementation Details

### Binary Format

The encoded data follows this format:

1. For strings:
   - u16 length prefix
   - raw string bytes

2. For arrays:
   - u16 length prefix
   - encoded elements

3. For maps:
   - u16 count of entries
   - encoded key-value pairs

### Struct Reflection

The encoder uses V's compile-time reflection to automatically handle structs:

```v
pub fn encode[T](obj T) ![]u8 {
    mut d := new()
    $for field in T.fields {
        // Encode each field based on its type
        $if field.typ is string {
            d.add_string(obj.$(field.name))
        } $else $if field.typ is int {
            d.add_int(obj.$(field.name))
        }
        // ... other types
    }
    return d.data
}
```

### Error Handling

The encoder will panic in these cases:
- String/list size exceeds 64KB
- Map has more than 64KB entries
- Unsupported type encountered

For production use, wrap encoding operations in error handling:

```v
encoded := encoder.encode(data) or {
    eprintln('Encoding failed: ${err}')
    return
}
```

## Best Practices

1. Always decode fields in the same order they were encoded
2. Use error handling when encoding/decoding structs
3. Be mindful of size limits for strings, lists and maps
4. Consider versioning if binary format may change
5. Test encoding/decoding with edge cases

## Testing

The module includes comprehensive tests covering:
- All primitive types
- Arrays and maps
- Nested structs
- Edge cases and limits
- Error conditions

Run tests with:
```bash
v test crystallib/data/encoder/
```
