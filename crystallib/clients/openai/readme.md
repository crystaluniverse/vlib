# OpenAI Client Module

This module provides a V client for interacting with OpenAI's API, allowing you to integrate OpenAI's services into your V applications.

## Setup

1. Get your API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Configure the client using heroscript:

```v
heroscript := "
!!openai.configure
    name:'default'
    openaikey:'your-api-key'    // Required: your OpenAI API key
    description:'My OpenAI API' // Optional
"

// Apply the configuration (only needs to be done once)
openai.play(heroscript: heroscript)!
```

## Usage

### Initialize Client
```v
// Get a configured client instance
mut client := openai.get(name: 'something')!

// Or use default instance if name wasn't specified in configuration
mut client := openai.get()!
```

### Examples

> see examples/clients/openai

### Complete Example

Here's a complete example showing common operations:

```v
#!/usr/bin/env -S v run

import freeflowuniverse.crystallib.clients.openai

fn main() {
    // Get client instance (uses default if no name specified)
    mut client := openai.get()!
    
    // Your OpenAI API operations here
    // (Add specific operation examples once implemented)
}
```

