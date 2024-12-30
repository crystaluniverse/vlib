# Hero Generation Example

## Getting started

Start by making all example scripts executable.
`chmod +x *.vsh`

### Step 1: Generate specification

### Step 2: Generate actor from specification

The script below generates the actor's OpenAPI handler from a given OpenAPI Specification. The generated code is written to `handler.v` in the example actor's module.

`generate_actor.vsh`

### Step 3: Run actor

The script below runs the actor's Redis RPC Queue Interface and uses the generated handler function to handle incoming RPCs. The Redis Interface listens to the RPC Queue assigned to the actor.

`run_interface_procedure.vsh`

### Step 3: Run server

The script below runs the actor's RPC Queue Listener and uses the generated handler function to handle incoming RPCs.

`run_interface_openapi.vsh`