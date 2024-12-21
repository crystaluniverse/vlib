#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.virt.hetzner
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.builder
import time
import os

fn main() {
    // Print header
    console.print_header('Hetzner API Examples')

    // Check for required environment variables
    user := os.getenv('HETZNER_USER')
    if user == '' {
        eprintln('Error: HETZNER_USER environment variable is not set')
        eprintln('Please set it using: export HETZNER_USER=your-username')
        exit(1)
    }

    password := os.getenv('HETZNER_PASSWD')
    if password == '' {
        eprintln('Error: HETZNER_PASSWD environment variable is not set')
        eprintln('Please set it using: export HETZNER_PASSWD=your-password')
        exit(1)
    }

    // Configure Hetzner using heroscript
    heroscript := "
    !!hetzner.configure
        name:'example'
        url:'https://robot-ws.your-server.de'
        user:'${user}'  // Using environment variable
        password:'${password}'  // Using environment variable
        whitelist:''  // Optional: comma-separated list of servers to whitelist
    "

    // Apply configuration (only needed once)
    // hetzner.play(heroscript: heroscript)!

    // Get client instance
    mut cl := hetzner.get(name: 'example')!
    
    // List all servers and print details
    console.print_header('Listing Servers')
    servers := cl.servers_list()!
    for server in servers {
        println('Server: ${server.server_name}')
        println('  IP: ${server.server_ip}')
        println('  Status: ${server.status}')
        println('  Location: ${server.dc}')
        println('  Product: ${server.product}')
        println('------------------')
    }
    
    // Get specific server information
    console.print_header('Getting Server Details')
    server_name := 'your_server_name' // Replace with actual server name
    mut server_info := cl.server_info_get(name: server_name)!
    println('Detailed info for ${server_name}:')
    println(server_info)
    
    // Example of rescue mode operation
    // Uncomment to test
    /*
    console.print_header('Testing Rescue Mode')
    rescue_result := cl.server_rescue(
        name: server_name
        wait: true
        crystal_install: true
    )!
    println('Rescue mode enabled:')
    println(rescue_result)
    */
    
    // Example of reset operation
    // Uncomment to test
    /*
    console.print_header('Testing Server Reset')
    reset_result := cl.server_reset(
        name: server_name
        wait: true
    )!
    println('Reset completed:')
    println(reset_result)
    */
    
    // Example of SSH connection after operations
    console.print_header('SSH Connection Example')
    mut b := builder.new()!
    mut n := b.node_new(ipaddr: server_info.server_ip)!
    
    // Example of installation operations
    // Uncomment to test
    /*
    n.crystal_install()!
    n.hero_compile_debug()!
    */
}
