#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import sync
import os
import rand
import time

const local_file = '/tmp/local_file.bin'
const remote_file = '/tmp/remote_file.bin'
    
// Function to test rolling hash performance
fn test_hash_performance() ! {
    // Create a 4KB chunk of random data
    chunk_size := 4096
    data_size := chunk_size * 2 // Extra space for rolling
    mut test_data := []u8{len: data_size}
    for i in 0..test_data.len {
        test_data[i] = u8(rand.int_in_range(0, 255)!)
    }

    iterations := 10000

    start_time := time.now()
    for _ in 0..iterations {
        _ := sync.calculate_rolling_hash(test_data[..chunk_size]).hex()
    }
    rolling_duration := time.since(start_time)


    println('Hash Performance Comparison:')
    println('Testing $iterations iterations on ${chunk_size}B chunks\n')
    
    println('Rolling Hash Performance:')
    println('- Total time: ${rolling_duration.milliseconds()}ms')
    println('- Operations per second: ${f64(iterations) / rolling_duration.seconds():.2f}')
    println('- Time per operation: ${rolling_duration.microseconds() / iterations}µs')
}

// Function to generate two test files with slight differences
fn generate_test_files(sizemb int) ! {
    mut content1 := []u8{len: 1024*1024*sizemb}
    mut content2 := []u8{len: 1024*1024*sizemb} 
    mut content3 := []u8{len: 1024*20} 

    // Fill with random data
    for i in 0..content3.len {
        content3[i] = u8(rand.int_in_range(0, 255)!)
    }
    
    // Fill with random data
    for i in 0..content1.len {
        content1[i] = u8(rand.int_in_range(0, 255)!)
        content2[i] = content1[i]
    }
    
    // Introduce some differences in the second file
    // Change a few bytes in different chunks
    content2[1024*100] = u8(rand.int_in_range(0, 255)!) // difference in chunk 0
    content2[1024*500] = u8(rand.int_in_range(0, 255)!) // difference in chunk 1
    content2[1024*600] = u8(rand.int_in_range(0, 255)!) // difference in chunk 3

    content2.insert(1024*300, content3)
    
    os.write_file_array('local_file.bin', content1)!
    os.write_file_array('remote_file.bin', content2)!
}

// Main function to demonstrate the functionality
fn do() ! {
    // Run performance test
    test_hash_performance()!

    generate := false

    // Generate test files
    if generate || !os.exists(local_file) || !os.exists(remote_file) {
        println("\nGenerating test files...")
        generate_test_files(10)!
    }

    // Step 1: Get the chunk hashes of both files
    println("\nHashing files...")
    println("hash start")
    local_hashes := sync.get_file_chunk_hashes(local_file)!
    println(local_hashes)
    println("hash end")
    
    // Step 2: Find unmatched segments
    println("\nFinding unmatched segments...")
    start_time := time.now()
    differing_chunks := sync.find_unmatched_segments(remote_file, local_hashes)!
    duration := time.since(start_time)
    
    println('\nFound ${differing_chunks.len} unmatched segments in ${duration.milliseconds()}ms')
    for chunk in differing_chunks {
        println('- Segment at position ${chunk.start}, length: ${chunk.length}')
    }
}

do() or { eprintln(err) }
