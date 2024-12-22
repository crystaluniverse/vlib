#!/usr/bin/env -S v -no-retry-compilation -d use_openssl -enable-globals run

import os
import time

// Function to get memory usage
fn get_memory_usage() string {
    // Get memory stats with clear column headers
    res := os.execute('ps -o pid,ppid,rss,vsz,%mem,command -p ${os.getpid()}')
    return res.output
}

// Print initial memory usage
println('=== Initial memory usage ===')
println(get_memory_usage())

mut child_pids := []int{}

// Create 100 forks
for i in 0..200 {
    pid := os.fork()
    if pid == 0 {
        // This code runs in child process
        println('Child process ${i}. PID: ${os.getpid()}')
        for {
            // Keep child process running
            time.sleep(1000 * time.millisecond)
        }
    } else {
        // This code runs in parent process
        child_pids << pid
    }
}

// In parent process
if child_pids.len > 0 {
    println('\n=== Created ${child_pids.len} child processes ===')
    
    // Give processes a moment to stabilize
    time.sleep(2 * time.second)
    
    println('\n=== Memory usage of all processes ===')
    // Get detailed memory stats for all processes
    mut pids := child_pids.clone()
    pids << os.getpid()
    res := os.execute('ps -o pid,ppid,rss,vsz,%mem,command -p ${pids.map(it.str()).join(" ")}')
    println(res.output)
    
    // Show total memory usage
    println('\n=== Total memory usage summary ===')
    res2 := os.execute('ps -o rss,vsz -p ${pids.map(it.str()).join(" ")} | tail -n +2 | awk \'{rss+=$1; vsz+=$2} END {printf "Total RSS (Physical Memory): %d KB\\nTotal VSZ (Virtual Memory): %d KB\\n", rss, vsz}\'')
    println(res2.output)
    
    // Cleanup children
    println('\n=== Cleaning up child processes ===')
    for pid in child_pids {
        os.system('kill -9 ${pid}')  // Using os.system to send SIGKILL
    }
    println('All child processes terminated')
}
