# Canva Module

This module provides a V client for interacting with the Canva API, enabling programmatic access to Canva's platform features.

## Setup

1. Create an account on [Canva Developer Portal](https://www.canva.com/developers/)
2. Create or select your application
3. Generate an API token
4. Configure the client using heroscript:
```v
import freeflowuniverse.crystallib.clients.canva

heroscript := "
!!canva.configure
    name:'my_instance'
    secret:'your-api-token-here'
"

// Apply the configuration (only needs to be done once)
canva.play(heroscript: heroscript)!


```

## Usage

### Initialize Client
```v
// Get a configured client instance
mut cl := canva.get(name: 'my_instance')!
```

### Examples

#### Download a Design
```v
// Get client instance
mut cl := canva.get('my_instance')!

// Download a design by ID
design_result := cl.download('your-design-id')!
println('Design downloaded: ${design_result}')
```

