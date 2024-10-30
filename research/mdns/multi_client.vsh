#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import net

import time

fn main() {
    // Create a UDP socket
    mut c := net.dial_udp("224.0.0.1:5000") or { panic('Failed to create socket') }
    println("multicast client started")
    // Main loop to receive messages    
    mut x:=0
    for {
        x+=1
        time.sleep(1 * time.second)
        mut buf := []u8{len: 1024}
        c.write_string("ping ${x}")!
        println("${x}")
    }
}
