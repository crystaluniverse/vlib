module sync

import crypto.md5
import hash.crc32
import os

const chunk_size = 4096 // 4KB chunks

// ChunkHash stores both quick and secure hashes for a chunk
pub struct ChunkHash {
pub:
    quick string  // CRC32 hash
    secure string // MD5 hash
}

// UnmatchedSegment represents a portion of the remote file that needs to be patched
pub struct UnmatchedSegment {
pub:
    start u64    // Start position in the remote file
    length u64   // Length of the unmatched segment
    data []u8    // The actual data that needs to be patched
}

// Function to read the file in chunks and return both quick and secure hashes
pub fn get_file_chunk_hashes(file_path string) ![]ChunkHash {
    mut file := os.open(file_path)!
    defer { file.close() }

    mut chunk_hashes := []ChunkHash{}
    mut buffer := []u8{len: chunk_size}
    
    for {
        read_bytes := file.read(mut buffer) or { break }
        if read_bytes == 0 {
            break
        }
        
        // Use unsafe to avoid clone warning since we're only reading
        chunk_data := unsafe { buffer[..read_bytes] }
        quick_hash := crc32.sum(chunk_data).hex() // CRC32 for quick comparison
        secure_hash := md5.sum(chunk_data).hex()   // MD5 for verification
        
        chunk_hashes << ChunkHash{
            quick: quick_hash
            secure: secure_hash
        }
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

    // Read the entire file
    for {
        read_bytes := file.read(mut buffer) or { break }
        if read_bytes == 0 {
            break
        }

        mut window_size := if read_bytes < chunk_size { read_bytes } else { chunk_size }
        
        // Use V's idiomatic for loop
        for i in 0 .. read_bytes - window_size + 1 {
            // Get current window
            window_data := unsafe { buffer[i..i + window_size] }
            quick_hash := crc32.sum(window_data).hex()
            mut found_match := false

            // Check if quick hash matches any local hash
            for local_hash in local_hashes {
                if quick_hash == local_hash.quick {
                    // Verify with MD5
                    secure_hash := md5.sum(window_data).hex()
                    if secure_hash == local_hash.secure {
                        found_match = true
                        
                        // If we were in an unmatched segment, close it
                        if in_unmatched_segment {
                            unmatched_segments << UnmatchedSegment{
                                start: unmatched_start
                                length: pos + u64(i) - unmatched_start
                                data: temp_buffer.clone()
                            }
                            temp_buffer.clear()
                            in_unmatched_segment = false
                        }
                        break
                    }
                }
            }

            if !found_match {
                // Start or continue an unmatched segment
                if !in_unmatched_segment {
                    unmatched_start = pos + u64(i)
                    in_unmatched_segment = true
                }
                temp_buffer << window_data[0] // Add the first byte of the window
            }
        }

        pos += u64(read_bytes)
        
        // If we're still in an unmatched segment at the end of the buffer
        if in_unmatched_segment && read_bytes < buffer.len {
            unmatched_segments << UnmatchedSegment{
                start: unmatched_start
                length: pos - unmatched_start
                data: temp_buffer.clone()
            }
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
