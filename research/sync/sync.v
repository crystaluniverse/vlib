module sync

import crypto.md5
import os

const chunk_size = 4096 // 4KB chunks

// Function to read the file in chunks and return the hash of each chunk
fn get_file_chunk_hashes(file_path string) ![]string {
    mut file := os.open(file_path)!
    defer { file.close() }

    mut chunk_hashes := []string{}
    mut buffer := []u8{len: chunk_size}
    
    for {
        read_bytes := file.read(mut buffer) or { break }
        if read_bytes == 0 {
            break
        }
        
        hash := md5.sum(buffer[..read_bytes])
        chunk_hashes << hash.str()
    }
    
    return chunk_hashes
}

// Function to compare two sets of chunk hashes
fn compare_chunk_hashes(local_hashes []string, remote_hashes []string) []int {
    mut differing_indices := []int{}
    
    // Compare chunk hashes
    for i in 0 .. local_hashes.len {
        if i >= remote_hashes.len || local_hashes[i] != remote_hashes[i] {
            differing_indices << i
        }
    }
    
    return differing_indices
}

// Function to get a specific chunk from a file
fn get_file_chunk(file_path string, index int) ![]u8 {
    mut file := os.open(file_path)!
    defer { file.close() }

    file.seek(int(index * chunk_size), .start)!
    mut buffer := []u8{len: chunk_size}
    read_bytes := file.read(mut buffer)!
    
    return buffer[..read_bytes]
}

// Main logic
fn main() {
    local_file := 'local_file.bin'
    remote_file := 'remote_file.bin'
    
    // Step 1: Get the chunk hashes of both files
    local_hashes := get_file_chunk_hashes(local_file) or { panic(err) }
    remote_hashes := get_file_chunk_hashes(remote_file) or { panic(err) }
    
    // Step 2: Compare chunk hashes and find differing chunks
    differing_chunks := compare_chunk_hashes(local_hashes, remote_hashes)
    
    // Step 3: Output the chunks that differ
    println('Differing chunks (indices): $differing_chunks')

    // Step 4: Send only the differing chunks
    for idx in differing_chunks {
        chunk_data := get_file_chunk(local_file, idx) or { panic(err) }
        println('Chunk $idx data: $chunk_data')
        
        // Simulate sending over the wire...
        // In reality, you would send this chunk over the network
    }
}
