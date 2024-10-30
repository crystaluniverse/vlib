#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import ourdb
import os

const million = 1000000

fn get_memory_mb() f64 {
    pid := os.getpid()
    // Use ps command to get RSS memory in KB, then convert to MB
    res := os.execute('ps -o rss= -p ${pid}')
    if res.exit_code == 0 {
        kb := res.output.trim_space().f64()
        return kb / 1024.0  // Convert KB to MB
    }
    return 0
}

fn main() {
    // Create output directory
    os.mkdir_all('/tmp/regiontest')!

    // Measure initial memory
    initial_mem := get_memory_mb()
    println('Initial memory usage: ${initial_mem:.2f} MB')

    mut db := ourdb.new(2 * million,.b4)

// Measure memory after buffer creation
    after_mem := get_memory_mb()
    println('Memory usage after buffer creation: ${after_mem:.2f} MB')
    println('Memory difference: ${after_mem - initial_mem:.2f} MB')
    
    mut db2 := ourdb.new(2 * million,.b4)    

    // Set test values at different positions
    test_data := {
        u32(1000): u16(100),
        u32(2000): u16(511),
        u32(5000): u16(65000),
        u32(10000): u16(32767),
        u32(50000): u16(1234),
        u32(100000): u16(5678),
        u32(500000): u16(9999),
        u32(1000000): u16(12345)
    }

    // Set values
    for pos, val in test_data {
        db.set(pos, val)!
        println('Set value ${val} at position ${pos}')
    }

    // Verify initial values
    println('\nVerifying initial values:')
    for pos, expected in test_data {
        val := db.get(pos)!
        println('Position ${pos}: expected=${expected}, got=${val}')
        assert val == expected
    }

    // Export in sparse format
    db.export_sparse('/tmp/regiontest/buffer_sparse.bin')!
    println('\nExported sparse buffer to /tmp/regiontest/buffer_sparse.bin')


    db2.import_sparse('/tmp/regiontest/buffer_sparse.bin')!
    println('Imported sparse buffer')

    // Verify all imported values
    println('\nVerifying imported values:')
    for pos, expected in test_data {
        val := db2.get(pos)!
        println('Position ${pos}: expected=${expected}, got=${val}')
        assert val == expected
    }

    // Verify zero values between test data points
    println('\nVerifying zero values between test points:')
    check_positions := [u32(0), 1500, 3000, 7500, 25000, 75000, 250000, 750000]
    for pos in check_positions {
        val := db2.get(pos)!
        println('Position ${pos}: expected=0, got=${val}')
        assert val == 0
    }

    // Final memory measurement
    final_mem := get_memory_mb()
    println('\nFinal memory usage: ${final_mem:.2f} MB')
    println('Total memory increase: ${final_mem - initial_mem:.2f} MB')
}
