#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import sync
import os

import rand
const local_file = '/tmp/local_file.bin'
const remote_file = '/tmp/remote_file.bin'
    

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

    generate:=false

    // Generate test files
    if generate || !os.exists(local_file) || !os.exists(remote_file){
        println("generate file")
        generate_test_files(10)!
    }

    // Step 1: Get the chunk hashes of both files
    
    println("hash start")
    local_hashes := sync.get_file_chunk_hashes(local_file)!
    println("hash end")

    //println(local_hashes)
    
    // Step 2: Compare chunk hashes and find differing chunks
    differing_chunks := sync.find_unmatched_segments(remote_file,local_hashes)!
    
    // // Step 3: Output the chunks that differ
    // println('Differing chunks (indices): $differing_chunks')

    // // Step 4: Send only the differing chunks
    // for idx in differing_chunks {
    //     chunk_data := sync.get_file_chunk(local_file, idx) or { 
    //         println('Error getting chunk $idx: $err')
    //         continue
    //     }
    //     println('Chunk $idx data length: ${chunk_data.len}')
        
    //     // Simulate sending over the wire...
    //     // In reality, you would send this chunk over the network
    // }
}


do() or {eprintln(err)}