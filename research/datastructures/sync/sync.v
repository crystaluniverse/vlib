module sync

import crypto.md5
import os

const chunk_size = 4096 // 4KB chunks
const prime = u32(16777619) // FNV prime
const window_size = 64 // Rolling hash window size

// ChunkHash stores both quick and secure hashes for a chunk
pub struct ChunkHash {
pub:
    quick string  // Rolling hash
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

// RollingHash implements an efficient rolling hash calculation
pub struct RollingHash {
mut:
    value u32
    window []u8
    window_size int
    pos int
    full bool
}

// Create a new rolling hash calculator
pub fn new_rolling_hash(window_size int) RollingHash {
    return RollingHash{
        value: 0
        window: []u8{len: window_size}
        window_size: window_size
        pos: 0
        full: false
    }
}

// Initialize the hash with the first window of data
pub fn (mut h RollingHash) init(data []u8) u32 {
    mut hash := u32(0)
    for i := 0; i < h.window_size && i < data.len; i++ {
        h.window[i] = data[i]
        hash = (hash * prime) + u32(data[i])
    }
    h.value = hash
    h.pos = 0
    h.full = data.len >= h.window_size
    return hash
}

// Roll the hash to the next position
pub fn (mut h RollingHash) roll(next_byte u8) u32 {
    old_byte := h.window[h.pos]
    h.window[h.pos] = next_byte
    
    if h.full {
        // Remove contribution of outgoing byte
        mut remove_val := u32(old_byte)
        for _ in 0..h.window_size-1 {
            remove_val *= prime
        }
        // Update hash value
        h.value = ((h.value - remove_val) * prime) + u32(next_byte)
    } else {
        // Still filling the initial window
        h.value = (h.value * prime) + u32(next_byte)
        if h.pos == h.window_size - 1 {
            h.full = true
        }
    }
    
    h.pos = (h.pos + 1) % h.window_size
    return h.value
}

// Calculate rolling hash for a chunk of data
pub fn calculate_rolling_hash(data []u8) u32 {
    mut hash := u32(0)
    for b in data {
        hash = (hash * prime) + u32(b)
    }
    return hash
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
        quick_hash := calculate_rolling_hash(chunk_data).hex()
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

    // Create rolling hash calculator with smaller window
    mut rolling_hash := new_rolling_hash(window_size)
    
    // Create lookup tables for quick comparison
    mut quick_lookup := map[string][]ChunkHash{}
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

        if pos == 0 {
            rolling_hash.init(buffer[..window_size])
        }

        // Slide the window byte by byte
        mut i := 0
        for i < read_bytes - window_size + 1 {
            if i > 0 {
                rolling_hash.roll(buffer[i + window_size - 1])
            }
            
            quick_hash := rolling_hash.value.hex()
            mut found_match := false

            // Check if quick hash matches any local hash
            if quick_hash in quick_lookup {
                // Get the full chunk starting at this position
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
