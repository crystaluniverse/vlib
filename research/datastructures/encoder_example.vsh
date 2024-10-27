#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import freeflowuniverse.crystallib.data.encoder
import crypto.ed25519
import time

struct AStruct {
pub mut:
    items   []string
    nr      int
    privkey []u8
    name    string
    children []ChildStruct
}

struct ChildStruct {
pub mut:
    name    string
    description    string
    data []u8
}


// encode encodes the struct using the encoder
pub fn (s AStruct) encode() ![]u8 {
    mut e := encoder.new()
    e.add_list_string(s.items)
    e.add_int(s.nr)
    e.add_bytes(s.privkey)
    e.add_string(s.name)
    
    // Encode children using generic encoder
    mut children_encoded := [][]u8{}
    for child in s.children {
        children_encoded << encoder.encode(child)!
    }
    e.add_u16(u16(children_encoded.len))  // Add length of children array
    for child_data in children_encoded {
        e.add_bytes(child_data)  // Add each encoded child
    }
    
    return e.data
}

// decode decodes the bytes back into an AStruct
pub fn (mut s AStruct) decode(data []u8) ! {
    mut e := encoder.decoder_new(data)
    s.items = e.get_list_string()
    s.nr = e.get_int()
    s.privkey = e.get_bytes()
    s.name = e.get_string()
    
    // Decode children using generic decoder
    children_len := int(e.get_u16())
    s.children = []ChildStruct{cap: children_len}
    for _ in 0 .. children_len {
        child_data := e.get_bytes()
        child := encoder.decode[ChildStruct](child_data)!
        s.children << child
    }
}


fn test_recursive_encode_decode() ! {
    child1 := ChildStruct{
        name: 'child1'
        description: 'first child'
        data: []u8{len: 3, init: u8(0x42)}
    }
    child2 := ChildStruct{
        name: 'child2'
        description: 'second child'
        data: []u8{len: 3, init: u8(0x43)}
    }

    original := AStruct{
        items: ['x', 'y', 'z']
        nr: 42
        privkey: []u8{len: 4, init: u8(0xaa)}
        name: 'parent struct'
        children: [child1, child2]
    }

    // Test encode method
    encoded := original.encode()!

    // Test decode method
    mut decoded := AStruct{}
    decoded.decode(encoded)!

    // Verify all fields match, including nested structures
    assert original.items == decoded.items
    assert original.nr == decoded.nr
    assert original.privkey == decoded.privkey
    assert original.name == decoded.name
    
    // Verify children
    assert decoded.children.len == original.children.len
    for i := 0; i < original.children.len; i++ {
        assert original.children[i].name == decoded.children[i].name
        assert original.children[i].description == decoded.children[i].description
        assert original.children[i].data == decoded.children[i].data
    }

    println('Recursive encoding/decoding successful - structs match including children')
}

fn test_performance() ! {
    // Create a sample object to encode/decode many times
    child := ChildStruct{
        name: 'child'
        description: 'test child'
        data: []u8{len: 8, init: u8(0x42)}
    }

    original := AStruct{
        items: ['test1', 'test2']
        nr: 42
        privkey: []u8{len: 16, init: u8(0xaa)}
        name: 'test struct'
        children: [child]
    }

    iterations := 1_000_000
    mut encoded_data := [][]u8{cap: iterations}

    // Time encoding
    mut sw := time.new_stopwatch()
    for _ in 0..iterations {
        encoded_data << original.encode()!
    }
    encode_time := sw.elapsed().seconds()
    
    // Time decoding
    sw.restart()
    for encoded in encoded_data {
        mut decoded := AStruct{}
        decoded.decode(encoded)!
    }
    decode_time := sw.elapsed().seconds()

    // Calculate and print results
    encode_ops_per_sec := f64(iterations) / encode_time
    decode_ops_per_sec := f64(iterations) / decode_time
    
    println('Performance Test Results (${iterations} iterations):')
    println('Encoding: ${encode_ops_per_sec:.0f} ops/sec (${encode_time:.3f} seconds total)')
    println('Decoding: ${decode_ops_per_sec:.0f} ops/sec (${decode_time:.3f} seconds total)')
}

fn main() {
    test_recursive_encode_decode() or { panic(err) }
    test_performance() or { panic(err) }
}
