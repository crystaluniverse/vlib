# Virtual File System (vfscore) Module

> is the interface, should not have an implementation

This module provides a pluggable virtual filesystem interface with one default implementation done for local.

1. Local filesystem implementation (direct passthrough to OS filesystem)
2. OurDB-based implementation (stores files and metadata in OurDB)

## Interface

The vfscore interface defines common operations for filesystem manipulation using a consistent naming pattern of `$subject_$method`:

### File Operations
- `file_create(path string) !FSEntry`
- `file_read(path string) ![]u8`
- `file_write(path string, data []u8) !`
- `file_delete(path string) !`

### Directory Operations
- `dir_create(path string) !FSEntry`
- `dir_list(path string) ![]FSEntry`
- `dir_delete(path string) !`

### Entry Operations (Common)
- `entry_exists(path string) bool`
- `entry_get(path string) !FSEntry`
- `entry_rename(old_path string, new_path string) !`
- `entry_copy(src_path string, dst_path string) !`

### Symlink Operations
- `link_create(target_path string, link_path string) !FSEntry`
- `link_read(path string) !string`

## Usage

```v
import vfscore

fn main() ! {
    // Create a local filesystem implementation
    mut local_vfs := vfscore.new_vfs('local', 'my_local_fs')!
    
    // Create and write to a file
    local_vfs.file_create('test.txt')!
    local_vfs.file_write('test.txt', 'Hello, World!'.bytes())!
    
    // Read file contents
    content := local_vfs.file_read('test.txt')!
    println(content.bytestr())
    
    // Create and list directory
    local_vfs.dir_create('subdir')!
    entries := local_vfs.dir_list('subdir')!
    
    // Create symlink
    local_vfs.link_create('test.txt', 'test_link.txt')!
    
    // Clean up
    local_vfs.file_delete('test.txt')!
    local_vfs.dir_delete('subdir')!
}
```

## Implementations

### Local Filesystem (LocalVFS)

The LocalVFS implementation provides a direct passthrough to the operating system's filesystem. It implements all vfscore operations by delegating to the corresponding OS filesystem operations.

Features:
- Direct access to local filesystem
- Full support for all vfscore operations
- Preserves file permissions and metadata
- Efficient for local file operations

### OurDB Filesystem (ourdb_fs)

The ourdb_fs implementation stores files and metadata in OurDB, providing a database-backed virtual filesystem.

Features:
- Persistent storage in OurDB
- Transactional operations
- Structured metadata storage
- Suitable for embedded systems or custom storage requirements

## Adding New Implementations

To create a new vfscore implementation:

1. Implement the `VFSImplementation` interface
2. Add your implementation to the `new_vfs` factory function
3. Ensure all required operations are implemented following the `$subject_$method` naming pattern
4. Add appropriate error handling and validation

## Error Handling

All operations that can fail return a `!` result type. Handle potential errors appropriately:

```v
// Example error handling
if file := vfscore.file_create('test.txt') {
    // Success case
    println('File created successfully')
} else {
    // Error case
    println('Failed to create file: ${err}')
}
```

## Testing

The module includes comprehensive tests for both implementations. Run tests using:

```bash
v test vfscore/
```

## Contributing

To add a new vfscore implementation:

1. Create a new file in the `vfscore` directory (e.g., `my_impl.v`)
2. Implement the `VFSImplementation` interface following the `$subject_$method` naming pattern
3. Add your implementation to `new_vfs()` in `interface.v`
4. Add tests to verify your implementation
5. Update documentation to include your implementation
