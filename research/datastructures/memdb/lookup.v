module memdb
import os

pub enum ByteSize {
    k65 = 2 //65k entries
    m16 = 3 //16 million
    b4 = 4 //4 billion
}

pub struct LookupTable {
pub mut:
    data []u8
    bytes_per_entry ByteSize
}

// Method to create a new lookup table
pub fn new(size u32, bytes_per_entry ByteSize) LookupTable {
    return LookupTable{
        data: []u8{len: int(size * u8(bytes_per_entry)), init: 0}
        bytes_per_entry: bytes_per_entry
    }
}

// Method to get value from a specific position
pub fn (b LookupTable) get(x u32) !u32 {
    entry_size := int(b.bytes_per_entry)
    if x * entry_size >= b.data.len {
        return error('Index out of bounds')
    }
    
    start := int(x) * entry_size
    mut value := u32(0)
    
    match b.bytes_per_entry {
        .k65 {
            value = u32(b.data[start]) | (u32(b.data[start + 1]) << 8)
            return u32(u16(value)) // Ensure 16-bit range for 2 bytes
        }
        .m16 {
            value = u32(b.data[start]) | 
                   (u32(b.data[start + 1]) << 8) |
                   (u32(b.data[start + 2]) << 16)
        }
        .b4 {
            value = u32(b.data[start]) | 
                   (u32(b.data[start + 1]) << 8) |
                   (u32(b.data[start + 2]) << 16) |
                   (u32(b.data[start + 3]) << 24)
        }
    }
    return value
}

// Method to set a value at a specific position
pub fn (mut b LookupTable) set(x u32, value u32) ! {
    entry_size := int(b.bytes_per_entry)
    if x * entry_size >= b.data.len {
        return error('Index out of bounds')
    }
    
    start := int(x) * entry_size
    
    match b.bytes_per_entry {
        .k65 {
            if value > 65535 {
                return error('Value too large for 2 bytes')
            }
            b.data[start] = u8(value & 0xff)
            b.data[start + 1] = u8((value >> 8) & 0xff)
        }
        .m16 {
            if value > 16777215 {
                return error('Value too large for 3 bytes')
            }
            b.data[start] = u8(value & 0xff)
            b.data[start + 1] = u8((value >> 8) & 0xff)
            b.data[start + 2] = u8((value >> 16) & 0xff)
        }
        .b4 {
            b.data[start] = u8(value & 0xff)
            b.data[start + 1] = u8((value >> 8) & 0xff)
            b.data[start + 2] = u8((value >> 16) & 0xff)
            b.data[start + 3] = u8((value >> 24) & 0xff)
        }
    }
}

// Method to delete an entry (set bytes to 0)
pub fn (mut b LookupTable) delete(x u32) ! {
    entry_size := int(b.bytes_per_entry)
    if x * entry_size >= b.data.len {
        return error('Index out of bounds')
    }
    
    start := int(x) * entry_size
    for i in 0..entry_size {
        b.data[start + i] = 0
    }
}

// Method to export the lookup table to a file
pub fn (b LookupTable) export_data(path string) ! {
    os.write_file(path, b.data.bytestr())!
}

// Method to export the table in a sparse format
pub fn (b LookupTable) export_sparse(path string) ! {
    mut output := []u8{}
    entry_size := int(b.bytes_per_entry)
    
    for i in 0 .. b.data.len / entry_size {
        val := b.get(u32(i)) or { continue }
        if val != 0 {
            // Write position as 4 bytes
            output << u8(i & 0xff)
            output << u8((i >> 8) & 0xff)
            output << u8((i >> 16) & 0xff)
            output << u8((i >> 24) & 0xff)
            
            // Write value based on entry size
            match b.bytes_per_entry {
                .k65 {
                    output << u8(val & 0xff)
                    output << u8((val >> 8) & 0xff)
                }
                .m16 {
                    output << u8(val & 0xff)
                    output << u8((val >> 8) & 0xff)
                    output << u8((val >> 16) & 0xff)
                }
                .b4 {
                    output << u8(val & 0xff)
                    output << u8((val >> 8) & 0xff)
                    output << u8((val >> 16) & 0xff)
                    output << u8((val >> 24) & 0xff)
                }
            }
        }
    }
    os.write_file(path, output.bytestr())!
}

// Method to import a lookup table from a file
pub fn (mut b LookupTable) import_data(path string) ! {
    b.data = os.read_bytes(path)!
}

// Method to import a sparse lookup table
pub fn (mut b LookupTable) import_sparse(path string) ! {
    sparse_data := os.read_bytes(path)!
    entry_size := int(b.bytes_per_entry)
    chunk_size := 4 + entry_size // 4 bytes for position + entry_size for value
    
    if sparse_data.len % chunk_size != 0 {
        return error('Invalid sparse data format: data length must be multiple of ${chunk_size}')
    }
    
    for i := 0; i < sparse_data.len; i += chunk_size {
        // Read position from first 4 bytes
        position := u32(sparse_data[i]) | 
                   (u32(sparse_data[i + 1]) << 8) |
                   (u32(sparse_data[i + 2]) << 16) |
                   (u32(sparse_data[i + 3]) << 24)
        
        // Read value based on entry size
        mut value := u32(0)
        match b.bytes_per_entry {
            .k65 {
                value = u32(sparse_data[i + 4]) |
                       (u32(sparse_data[i + 5]) << 8)
            }
            .m16 {
                value = u32(sparse_data[i + 4]) |
                       (u32(sparse_data[i + 5]) << 8) |
                       (u32(sparse_data[i + 6]) << 16)
            }
            .b4 {
                value = u32(sparse_data[i + 4]) |
                       (u32(sparse_data[i + 5]) << 8) |
                       (u32(sparse_data[i + 6]) << 16) |
                       (u32(sparse_data[i + 7]) << 24)
            }
        }
        
        b.set(position, value)!
    }
}
