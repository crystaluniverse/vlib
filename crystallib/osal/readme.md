# Operating System Abstraction Layer (OSAL)

A comprehensive operating system abstraction layer for V that provides platform-independent system operations, process management, and network utilities.

## Features

- Platform detection and system information
- Process execution and management
- Network utilities (ping, TCP port testing)
- Environment variable handling
- File system operations
- SSH key management
- Profile path management

## Platform Detection

```v
import freeflowuniverse.crystallib.osal

// Get platform type
platform := osal.platform()
if platform == .osx {
    // macOS specific code
}

// Platform-specific checks
if osal.is_linux() {
    // Linux specific code
}
if osal.is_osx_arm() {
    // Apple Silicon specific code
}

// CPU architecture
cpu := osal.cputype()
if cpu == .arm {
    // ARM specific code
}

// System information
hostname := osal.hostname()!
init_system := osal.initname()!  // e.g., systemd, bash, zinit
```

## Process Execution

The module provides flexible process execution with extensive configuration options:

```v
// Simple command execution
job := osal.exec(cmd: 'ls -la')!
println(job.output)

// Execute with error handling
job := osal.exec(Command{
    cmd: 'complex_command'
    timeout: 3600        // timeout in seconds
    retry: 3             // retry count
    work_folder: '/tmp'  // working directory
    environment: {       // environment variables
        'PATH': '/usr/local/bin'
    }
    stdout: true         // show output
    raise_error: true    // raise error on failure
})!

// Silent execution
output := osal.execute_silent('command')!

// Interactive shell execution
osal.execute_interactive('bash command')!

// Debug mode execution
output := osal.execute_debug('command')!
```

### Job Status and Error Handling

```v
// Check job status
if job.status == .done {
    println('Success!')
} else if job.status == .error_timeout {
    println('Command timed out')
}

// Error handling with specific error types
job := osal.exec(cmd: 'invalid_command') or {
    match err.error_type {
        .exec { println('Execution error') }
        .timeout { println('Command timed out') }
        .args { println('Invalid arguments') }
        else { println(err) }
    }
    return
}
```

## Network Utilities

### Ping

```v
// Simple ping
result := osal.ping(address: '8.8.8.8')!
assert result == .ok

// Advanced ping configuration
result := osal.ping(PingArgs{
    address: '8.8.8.8'
    count: 3        // number of pings
    timeout: 2      // timeout in seconds
    retry: 1        // retry attempts
})!

match result {
    .ok { println('Host is reachable') }
    .timeout { println('Host timed out') }
    .unknownhost { println('Unknown host') }
}
```

### TCP Port Testing

```v
// Test if port is open
is_open := osal.tcp_port_test(TcpPortTestArgs{
    address: '192.168.1.1'
    port: 22
    timeout: 2000  // milliseconds
})

if is_open {
    println('Port is open')
}

// Get public IP address
pub_ip := osal.ipaddr_pub_get()!
println('Public IP: ${pub_ip}')
```

## Profile Management

Manage system PATH and other profile settings:

```v
// Add/remove paths from system PATH
osal.profile_path_add_remove(
    paths2delete: 'go/bin',
    paths2add: '~/hero/bin,~/usr/local/bin'
)!
```

## Environment Variables

```v
// Get environment variable
value := osal.env_get('PATH')!

// Set environment variable
osal.env_set('MY_VAR', 'value')!

// Check if environment variable exists
exists := osal.env_exists('MY_VAR')
```

## Notes

- All commands are executed from temporary scripts in `/tmp/execscripts`
- Failed script executions are preserved for debugging
- Successful script executions are automatically cleaned up
- Platform-specific behavior is automatically handled
- Timeout and retry mechanisms are available for robust execution
- Environment variables and working directories can be specified per command
- Interactive and non-interactive modes are supported
- Debug mode provides additional execution information

## Error Handling

The module provides detailed error information:

- Exit codes
- Standard output and error streams
- Execution time and duration
- Process status
- Retry counts
- Error types (execution, timeout, arguments)

## Platform Support

- macOS (Intel and ARM)
- Ubuntu
- Alpine Linux
- Arch Linux
- SUSE (partial)

CPU architectures:
- Intel (x86_64)
- ARM (arm64/aarch64)
- 32-bit variants (intel32, arm32)
