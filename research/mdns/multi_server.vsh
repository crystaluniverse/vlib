#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import net



fn main() {
    // Create a UDP socket
    mut c := net.listen_udp("224.0.0.1:5000") or { panic('Failed to create socket') }
    println("multicast server started")
    // Main loop to receive messages
    for {
        mut buf := []u8{len: 1024}
        read, _ := c.read(mut buf)!
        txt:=buf[0..read].bytestr()
		println('server received: ${txt}' )
    }
}
