# Hetzner Module

This module provides a V client for interacting with Hetzner's Robot API, allowing you to manage dedicated servers programmatically.

## Setup

1. Create an account on [Hetzner Robot](https://robot.hetzner.com/preferences/index)
2. Configure the client using heroscript:
```v
import freeflowuniverse.crystallib.virt.hetzner

heroscript := "
!!hetzner.configure
    name:'my_instance'
    url:'https://robot-ws.your-server.de'
    user:'your-username'
    password:'your-password'
    whitelist:''  // comma separated list of servers to whitelist
"

// Apply the configuration (only needs to be done once)
hetzner.play(heroscript: heroscript)!
```

## Usage

### Initialize Client
```v
// Get a configured client instance
mut cl := hetzner.get(name: 'my_instance')!
```

### Configuration Notes

- The client uses crystallib's httpconnection module which provides:
  - Built-in Redis caching for API responses
  - Automatic retry mechanism for failed requests
  - Proper Basic auth handling
  - Consistent error handling

### Examples

> see examples/virt/hetzner

### Available Operations

#### List Servers
```v
// Get list of all servers
servers := cl.servers_list()!
```

#### Get Server Information
```v
// Get server info by name
server_info := cl.server_info_get(name: 'server_name')!

// Get server info by ID
server_info := cl.server_info_get(id: 123)!
```

The ServerInfo struct contains:
- server_ip: Primary IP address
- server_ipv6_net: IPv6 network
- server_number: Server ID
- server_name: Server name
- product: Product description
- dc: Datacenter location
- traffic: Traffic information
- status: Current server status
- cancelled: Cancellation status
- paid_until: Payment status date
- ip: List of IP addresses
- subnet: List of subnets

#### Server Management Operations

##### Reset Server
```v
// Reset server with wait for completion
cl.server_reset(name: "server_name", wait: true)!

// Reset server without waiting
cl.server_reset(name: "server_name", wait: false)!
```

##### Enable Rescue Mode
```v
// Enable rescue mode and wait for completion
cl.server_rescue(name: "server_name", wait: true)!

// Enable rescue mode with automatic Crystal installation
cl.server_rescue(name: "server_name", wait: true, crystal_install: true)!
```

## Complete Example

Here's a complete example showing common operations:

```v
#!/usr/bin/env -S v run

import freeflowuniverse.crystallib.virt.hetzner
import freeflowuniverse.crystallib.ui.console

fn main() {
    // Get client instance
    mut cl := hetzner.get('my_instance')!
    
    // List all servers
    servers := cl.servers_list()!
    println('Available servers:')
    println(servers)
    
    // Get specific server info
    mut server_info := cl.server_info_get(name: 'my_server')!
    println('Server details:')
    println(server_info)
    
    // Put server in rescue mode
    cl.server_rescue(name: "my_server", wait: true)!
    
    // Reset server
    cl.server_reset(name: "my_server", wait: true)!
}
```

## Features

- Server listing and information retrieval
- Hardware reset functionality
- Rescue mode management
- SSH key management
- Automatic server status monitoring
- Built-in caching for API responses
- Integration with Crystal installation tools

## Notes

- The module uses Redis for caching API responses (60-second cache duration)
- Server operations that include `wait: true` will monitor the server until the operation completes
- Reset operations with `wait: true` will timeout after 5 minutes if the server doesn't come back online
- The module automatically manages SSH keys for rescue mode operations
- API description is on https://robot.hetzner.com/doc/webservice/en.html#preface
