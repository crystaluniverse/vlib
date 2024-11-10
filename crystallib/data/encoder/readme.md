# Crystal Binary Encoder Protocol

A high-performance, compact binary encoder designed for minimal binary size and fast serialization.

## Features

- Version byte for backward compatibility
- Compact binary representation
- Fast serialization/deserialization
- Support for complex nested structures
- Type safety

## Format

The binary format starts with a version byte (currently v1), followed by the encoded data:

```
[version_byte][encoded_data...]
```

## Supported Types

- Primitive types: u8, u16, u32, u64, int
- Strings (prefixed with u16 length)
- Byte arrays (prefixed with u32 length)
- Lists of primitives and strings
- Maps with string keys
- Time (unix nano)
- Nested structs

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

## Best Practices

1. Always check the version byte when decoding to ensure compatibility
2. Encode fields in a consistent order
3. For nested structs, encode each field in depth-first order
4. Use appropriate length prefixes for variable-length data
5. Keep struct definitions in sync between encoding and decoding

## Size Limits

- Strings and lists are limited to 64KB (u16 max)
- Byte arrays can be up to 4GB (u32 max)
- Maps are limited to 64KB entries

## Error Handling

The encoder will panic if:
- Strings or lists exceed 64KB
- Maps have more than 64KB items
- Invalid data types are provided

For production use, consider wrapping encoding operations in `recover()` blocks.
