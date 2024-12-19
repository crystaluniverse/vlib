
# V Binary Encoder/Decoder

A high-performance binary encoder/decoder module for V that provides efficient serialization and deserialization of data structures. The encoder supports automatic encoding/decoding of structs using V's compile-time reflection capabilities.

## Features

- Automatic struct encoding/decoding using compile-time reflection
- Support for primitive types, arrays, maps, and nested structs
- Compact binary format with length prefixing
- Size limits to prevent memory issues (64KB for strings/lists)
- Comprehensive error handling
- Built-in versioning support

## Format

The binary format starts with a version byte (currently v1), followed by the encoded data:

```
[version_byte][encoded_data...]
```

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

## Example

Here's a complete example showing how to encode nested structs:

```v
import freeflowuniverse.crystallib.data.encoder

// Define some nested structs
struct Address {
    street string
    number int
    country string
}

struct Person {
    name string
    age int
    addresses []Address    // nested array of structs
    metadata map[string]string
}

// Example usage
fn main() {
    // Create test data
    mut person := Person{
        name: 'John Doe'
        age: 30
        addresses: [
            Address{
                street: 'Main St'
                number: 123
                country: 'USA'
            },
            Address{
                street: 'Side St'
                number: 456
                country: 'Canada'
            }
        ]
        metadata: {
            'id': 'abc123'
            'type': 'customer'
        }
    }

    // Encode the data
    mut e := encoder.new()
    
    // Add version byte (v1)
    e.add_u8(1)
    
    // Encode the Person struct
    e.add_string(person.name)
    e.add_int(person.age)
    
    // Encode the addresses array
    e.add_u16(u16(person.addresses.len))  // number of addresses
    for addr in person.addresses {
        e.add_string(addr.street)
        e.add_int(addr.number)
        e.add_string(addr.country)
    }
    
    // Encode the metadata map
    e.add_map_string(person.metadata)
    
    // The binary data is now in e.data
    encoded := e.data
    
    // Later, when decoding, first byte tells us the version
    version := encoded[0]
    assert version == 1
}
```

## Binary Format Details

For the example above, the binary layout would be:

```
[1]                     // version byte (v1)
[len][John Doe]         // name (u16 length + bytes)
[30]                    // age (int/u32)
[2]                     // number of addresses (u16)
  [len][Main St]        // address 1 street
  [123]                 // address 1 number
  [len][USA]           // address 1 country
  [len][Side St]       // address 2 street
  [456]                // address 2 number
  [len][Canada]        // address 2 country
[2]                     // number of metadata entries (u16)
  [len][id]            // key 1
  [len][abc123]        // value 1
  [len][type]          // key 2
  [len][customer]      // value 2
```



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

