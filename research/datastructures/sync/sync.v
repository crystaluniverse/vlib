module sync

import crypto.md5
import os

const chunk_size = 4096 // 4KB chunks
const window_size = 64 // Rolling hash window size
const table_size = 256 // Size of the lookup table

// ChunkHash stores both quick and secure hashes for a chunk
pub struct ChunkHash {
pub:
    quick u32     // Rolling hash (BUZHASH)
    secure string // MD5 hash
    offset u64    // Chunk offset in file
}

// UnmatchedSegment represents a portion of the remote file that needs to be patched
pub struct UnmatchedSegment {
pub:
    start u64    // Start position in the remote file
    length u64   // Length of the unmatched segment
    data []u8    // The actual data that needs to be patched
}

// BuzHash implements an efficient rolling hash calculation
pub struct BuzHash {
mut:
    hash u32
    window []u8
    pos int
    full bool
    lookup_table []u32
}

// Precomputed lookup table for BUZHASH
[direct_array_access]
fn generate_lookup_table() []u32 {
    return [
        u32(0x12345678), 0x23456789, 0x34567890, 0x45678901, 0x56789012, 0x67890123, 0x78901234, 0x89012345,
        0x90123456, 0xA1234567, 0xB2345678, 0xC3456789, 0xD4567890, 0xE5678901, 0xF6789012, 0x07890123,
        0x18901234, 0x29012345, 0x30123456, 0x41234567, 0x52345678, 0x63456789, 0x74567890, 0x85678901,
        0x96789012, 0xA7890123, 0xB8901234, 0xC9012345, 0xDA123456, 0xEB234567, 0xFC345678, 0x0D456789,
        0x1E567890, 0x2F678901, 0x30789012, 0x41890123, 0x52901234, 0x63A12345, 0x74B23456, 0x85C34567,
        0x96D45678, 0xA7E56789, 0xB8F67890, 0xC9078901, 0xDA189012, 0xEB290123, 0xFC301234, 0x0D412345,
        0x1E523456, 0x2F634567, 0x30745678, 0x41856789, 0x52967890, 0x63A78901, 0x74B89012, 0x85C90123,
        0x96DA1234, 0xA7EB2345, 0xB8FC3456, 0xC90D4567, 0xDA1E5678, 0xEB2F6789, 0xFC307890, 0x0D418901,
        0x1E529012, 0x2F630123, 0x30741234, 0x41852345, 0x52963456, 0x63A74567, 0x74B85678, 0x85C96789,
        0x96DA7890, 0xA7EB8901, 0xB8FC9012, 0xC90DA123, 0xDA1EB234, 0xEB2FC345, 0xFC30D456, 0x0D41E567,
        0x1E52F678, 0x2F630789, 0x30741890, 0x41852901, 0x52963A12, 0x63A74B23, 0x74B85C34, 0x85C96D45,
        0x96DA7E56, 0xA7EB8F67, 0xB8FC9078, 0xC90DA189, 0xDA1EB290, 0xEB2FC301, 0xFC30D412, 0x0D41E523,
        0x1E52F634, 0x2F630745, 0x30741856, 0x41852967, 0x52963A78, 0x63A74B89, 0x74B85C90, 0x85C96DA1,
        0x96DA7EB2, 0xA7EB8FC3, 0xB8FC90D4, 0xC90DA1E5, 0xDA1EB2F6, 0xEB2FC307, 0xFC30D418, 0x0D41E529,
        0x1E52F630, 0x2F630741, 0x30741852, 0x41852963, 0x52963A74, 0x63A74B85, 0x74B85C96, 0x85C96DA7,
        0x96DA7EB8, 0xA7EB8FC9, 0xB8FC90DA, 0xC90DA1EB, 0xDA1EB2FC, 0xEB2FC30D, 0xFC30D41E, 0x0D41E52F
    ]
}

// Create a new BUZHASH calculator
pub fn new_buzhash() BuzHash {
    return BuzHash{
        hash: 0
        window: []u8{len: window_size}
        pos: 0
        full: false
        lookup_table: generate_lookup_table()
    }
}

// Update the rolling hash with a new byte
[direct_array_access; inline]
pub fn (mut b BuzHash) update(byte_val u8) u32 {
    if b.full {
        old_byte := b.window[b.pos]
        b.hash = (b.hash << 1) | (b.hash >> 31) // Rotate left by 1
        b.hash ^= b.lookup_table[old_byte]
    }

    b.hash ^= b.lookup_table[byte_val]
    b.window[b.pos] = byte_val

    b.pos++
    if b.pos == window_size {
        b.pos = 0
        b.full = true
    }

    return b.hash
}

// Reset the hash state
pub fn (mut b BuzHash) reset() {
    b.hash = 0
    b.pos = 0
    b.full = false
    for i := 0; i < window_size; i++ {
        b.window[i] = 0
    }
}

// Calculate rolling hash for a chunk of data
pub fn calculate_rolling_hash(data []u8) u32 {
    mut hasher := new_buzhash()
    for b in data {
        hasher.update(b)
    }
    return hasher.hash
}

// Function to read the file in chunks and return both quick and secure hashes
pub fn get_file_chunk_hashes(file_path string) ![]ChunkHash {
    mut file := os.open(file_path)!
    defer { file.close() }

    mut chunk_hashes := []ChunkHash{}
    mut buffer := []u8{len: chunk_size}
    mut offset := u64(0)
    
    for {
        read_bytes := file.read(mut buffer) or { break }
        if read_bytes == 0 {
            break
        }
        
        chunk_data := unsafe { buffer[..read_bytes] }
        quick_hash := calculate_rolling_hash(chunk_data)
        secure_hash := md5.sum(chunk_data).hex()
        
        chunk_hashes << ChunkHash{
            quick: quick_hash
            secure: secure_hash
            offset: offset
        }
        
        offset += u64(read_bytes)
    }
    
    return chunk_hashes
}

// Function to find unmatched segments in remote file using rolling hash
pub fn find_unmatched_segments(remote_path string, local_hashes []ChunkHash) ![]UnmatchedSegment {
    mut file := os.open(remote_path)!
    defer { file.close() }

    mut unmatched_segments := []UnmatchedSegment{}
    mut buffer := []u8{len: chunk_size * 2} // Double buffer size for rolling window
    mut pos := u64(0)
    mut unmatched_start := u64(0)
    mut in_unmatched_segment := false
    mut temp_buffer := []u8{}

    // Create BUZHASH calculator
    mut rolling_hash := new_buzhash()
    
    // Create lookup tables for quick comparison
    mut quick_lookup := map[u32][]ChunkHash{}
    for hash in local_hashes {
        if hash.quick !in quick_lookup {
            quick_lookup[hash.quick] = []ChunkHash{}
        }
        quick_lookup[hash.quick] << hash
    }

    // Read the file in smaller chunks for more granular matching
    for {
        read_bytes := file.read(mut buffer) or { break }
        if read_bytes == 0 {
            break
        }

        // Process the buffer byte by byte
        mut i := 0
        for i < read_bytes {
            quick_hash := rolling_hash.update(buffer[i])
            mut found_match := false

            // Only check for matches when we have a full window
            if rolling_hash.full {
                // Check if quick hash matches any local hash
                if quick_hash in quick_lookup {
                    // Get the full chunk starting at current position
                    mut chunk_data := []u8{}
                    if i + chunk_size <= read_bytes {
                        chunk_data = unsafe { buffer[i..i + chunk_size] }
                    } else {
                        // Need to read more data to complete the chunk
                        mut full_chunk := []u8{len: chunk_size}
                        unsafe {
                            // Copy what we have
                            for j := 0; j < read_bytes - i; j++ {
                                full_chunk[j] = buffer[i + j]
                            }
                        }
                        
                        // Read remaining bytes if needed
                        remaining := chunk_size - (read_bytes - i)
                        mut remaining_buf := []u8{len: remaining}
                        bytes_read := file.read(mut remaining_buf) or { 0 }
                        if bytes_read > 0 {
                            unsafe {
                                for j := 0; j < bytes_read; j++ {
                                    full_chunk[read_bytes - i + j] = remaining_buf[j]
                                }
                            }
                        }
                        chunk_data = full_chunk.clone()
                    }

                    secure_hash := md5.sum(chunk_data).hex()
                    
                    // Check against all chunks with matching quick hash
                    for local_hash in quick_lookup[quick_hash] {
                        if secure_hash == local_hash.secure {
                            found_match = true
                            
                            // Close current unmatched segment if exists
                            if in_unmatched_segment {
                                unmatched_segments << UnmatchedSegment{
                                    start: unmatched_start
                                    length: pos + u64(i) - unmatched_start
                                    data: temp_buffer.clone()
                                }
                                temp_buffer.clear()
                                in_unmatched_segment = false
                            }
                            
                            // Skip the matched chunk
                            i += chunk_size - 1
                            break
                        }
                    }
                }
            }

            if !found_match {
                if !in_unmatched_segment {
                    unmatched_start = pos + u64(i)
                    in_unmatched_segment = true
                }
                temp_buffer << buffer[i]
            }
            i++
        }

        pos += u64(read_bytes)
    }

    // Handle any remaining unmatched segment
    if in_unmatched_segment {
        unmatched_segments << UnmatchedSegment{
            start: unmatched_start
            length: pos - unmatched_start
            data: temp_buffer.clone()
        }
    }

    return unmatched_segments
}

// Function to get a specific chunk from a file
pub fn get_file_chunk(file_path string, index int) ![]u8 {
    mut file := os.open(file_path)!
    defer { file.close() }

    file.seek(index * chunk_size, .start)!
    mut buffer := []u8{len: chunk_size}
    read_bytes := file.read(mut buffer)!
    
    return buffer[..read_bytes]
}
