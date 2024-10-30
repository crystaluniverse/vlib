## low-level FUSE operations:

```v
struct C.fuse_lowlevel_ops {
    lookup     fn (req &fuse_req_t, parent u64, name &char)
    forget     fn (req &fuse_req_t, ino u64, nlookup u64)
    getattr    fn (req &fuse_req_t, ino u64, fi &fuse_file_info)
    setattr    fn (req &fuse_req_t, ino u64, attr &stat, to_set int, fi &fuse_file_info)
    readlink   fn (req &fuse_req_t, ino u64)
    opendir    fn (req &fuse_req_t, ino u64, fi &fuse_file_info)
    readdir    fn (req &fuse_req_t, ino u64, size size_t, off u64, fi &fuse_file_info)
    open       fn (req &fuse_req_t, ino u64, fi &fuse_file_info)
    read       fn (req &fuse_req_t, ino u64, size size_t, off u64, fi &fuse_file_info)
    write      fn (req &fuse_req_t, ino u64, buf &char, size size_t, off u64, fi &fuse_file_info)
}
```

Core Low-Level Operations:

1. `lookup` - Inode Lookup
```v
lookup fn (req &fuse_req_t, parent u64, name &char)
```
- Translates (parent_inode, name) to child inode
- Must respond with `fuse_reply_entry` containing:
  - Inode number
  - Generation number
  - Attributes
- Used for path resolution

1. `forget` - Forget Inode
```v
forget fn (req &fuse_req_t, ino u64, nlookup u64)
```
- Decrements lookup count for inode
- Called when kernel drops inode from cache
- No reply needed
- Used for inode lifetime management

1. `getattr` - Get Inode Attributes
```v
getattr fn (req &fuse_req_t, ino u64, fi &fuse_file_info)
```
- Gets attributes for specific inode
- Must respond with `fuse_reply_attr`
- Different from high-level API as it works with inodes directly

1. `setattr` - Set Inode Attributes
```v
setattr fn (req &fuse_req_t, ino u64, attr &stat, to_set int, fi &fuse_file_info)
```
- Changes inode attributes
- `to_set` specifies which attributes to change
- Must respond with new attributes

1. `readdir` - Read Directory
```v
readdir fn (req &fuse_req_t, ino u64, size size_t, off u64, fi &fuse_file_info)
```
- Lists directory contents using inode numbers
- Must respond with `fuse_reply_buf`
- Entries must include:
  - Inode number
  - Offset
  - Type
  - Name

1. `create` - Create New Inode
```v
create fn (req &fuse_req_t, parent u64, name &char, mode mode_t, fi &fuse_file_info)
```
- Creates new inode in parent directory
- Must respond with new entry information

Response Functions:
```v
fn C.fuse_reply_entry(req &fuse_req_t, e &fuse_entry_param) int
fn C.fuse_reply_attr(req &fuse_req_t, attr &stat, timeout f64) int
fn C.fuse_reply_buf(req &fuse_req_t, buf &char, size size_t) int
fn C.fuse_reply_err(req &fuse_req_t, err int) int
```

Key Differences from High-Level API:
1. Works with inodes instead of paths
2. Explicit request/response handling
3. More control over inode lifecycle
4. Direct kernel interface
5. Better performance potential
6. More complex implementation required

Example of inode tracking structure:
```v
struct InodeData {
mut:
    ino        u64
    generation u64
    nlookup    u64
    attr       C.stat
    data       []u8
}

struct LowLevelFS {
mut:
    inodes     map[u64]InodeData
    next_ino   u64
    mutex      sync.Mutex
}
```

Would you like me to provide a complete low-level FUSE implementation example or explain any specific aspect in more detail?



`fuse_file_info` is a structure used in FUSE operations to carry file state and operation flags between the kernel and FUSE filesystem. Here's its structure and detailed explanation:

```c
struct fuse_file_info {
    // Flags used for opening (read/write mode)
    int flags;

    // File handle - can be used by filesystem to store private data
    uint64_t fh;

    // Lock owner - used for file locking
    uint64_t lock_owner;

    // Bitfields:
    unsigned int direct_io:1;      // Skip page cache, direct I/O
    unsigned int keep_cache:1;     // Cache file data after close
    unsigned int flush:1;          // Flush cached data
    unsigned int nonseekable:1;    // The file is not seekable
    unsigned int cache_readdir:1;  // Cache readdir entries
    unsigned int flock_release:1;  // Release flock on close
    unsigned int padding:27;       // Reserved bits
};
```

Key Fields Explained:

1. `flags`
```v
// Common flags
O_RDONLY    // Open for reading only
O_WRONLY    // Open for writing only
O_RDWR      // Open for reading and writing
O_APPEND    // Append mode
O_CREAT     // Create file if it doesn't exist
O_TRUNC     // Truncate file to zero length
O_EXCL      // Exclusive creation
```

2. `fh` (File Handle)
```v
// Example usage
fn open(path &char, fi &fuse_file_info) int {
    // Store private data
    fi.fh = u64(MyFileHandle{
        fd: actual_file_descriptor
        // other data...
    })
    return 0
}

fn read(path &char, buf voidptr, size size_t, offset i64, fi &fuse_file_info) int {
    // Retrieve private data
    handle := &MyFileHandle(fi.fh)
    // Use handle.fd for operations
}
```

3. Capability Flags Usage Example:
```v
fn open(path &char, fi &fuse_file_info) int {
    // Enable direct I/O (bypass page cache)
    fi.direct_io = 1

    // Keep data in cache after close
    fi.keep_cache = 1

    // Mark file as non-seekable (streaming)
    fi.nonseekable = 1

    return 0
}
```

Real-world Example with File Handle:
```v
struct FileHandle {
mut:
    offset    i64
    buffer    []u8
    is_dirty  bool
}

struct MemoryFS {
mut:
    files map[string]&FileHandle
    mutex sync.Mutex
}

fn (mut fs MemoryFS) open(path &char, fi &fuse_file_info) int {
    path_str := unsafe { cstring_to_vstring(path) }
    
    fs.mutex.@lock()
    defer { fs.mutex.unlock() }
    
    handle := &FileHandle{
        offset: 0
        buffer: []u8{}
        is_dirty: false
    }
    
    // Store handle in fh
    fi.fh = u64(handle)
    
    // Set capabilities based on open flags
    if (fi.flags & O_DIRECT) != 0 {
        fi.direct_io = 1
    }
    
    if (fi.flags & O_APPEND) != 0 {
        handle.offset = handle.buffer.len
    }
    
    return 0
}

fn (mut fs MemoryFS) read(path &char, buf voidptr, size size_t, offset i64, fi &fuse_file_info) int {
    handle := &FileHandle(fi.fh)
    
    fs.mutex.@lock()
    defer { fs.mutex.unlock() }
    
    if offset >= handle.buffer.len {
        return 0
    }
    
    mut read_size := size
    if offset + size > handle.buffer.len {
        read_size = handle.buffer.len - offset
    }
    
    unsafe {
        C.memcpy(buf, &handle.buffer[offset], read_size)
    }
    
    handle.offset = offset + read_size
    return int(read_size)
}

fn (mut fs MemoryFS) release(path &char, fi &fuse_file_info) int {
    handle := &FileHandle(fi.fh)
    
    fs.mutex.@lock()
    defer { fs.mutex.unlock() }
    
    if handle.is_dirty {
        // Save changes if needed
    }
    
    // Clean up handle
    unsafe { free(handle) }
    fi.fh = 0
    
    return 0
}
```

## Common Usage Patterns:

1. Sequential Read/Write:
```v
fn (mut fs MemoryFS) read_sequential(fi &fuse_file_info, buf voidptr, size size_t) int {
    handle := &FileHandle(fi.fh)
    result := fs.read(buf, size, handle.offset)
    if result > 0 {
        handle.offset += result
    }
    return result
}
```

2. Cached vs Direct I/O:
```v
fn (mut fs MemoryFS) open_with_caching(path &char, fi &fuse_file_info) int {
    if fs.should_cache(path) {
        fi.keep_cache = 1
    } else {
        fi.direct_io = 1
    }
    return 0
}
```

3. File Locking:
```v
fn (mut fs MemoryFS) lock(path &char, fi &fuse_file_info, cmd int, lock &flock) int {
    handle := &FileHandle(fi.fh)
    lock_owner := fi.lock_owner
    // Implement locking logic
    return 0
}
```

The `fuse_file_info` structure is crucial for:
- Maintaining file state between operations
- Controlling caching behavior
- Managing file handles and private data
- Supporting file locking
- Optimizing I/O operations



## Inode Structure


An inode (index node) represents a file system object (file, directory, symbolic link, etc.) in Unix-like systems. It contains all the metadata about the file except its name and actual data. The path must be constructed by traversing the directory hierarchy using parent-child inode relationships.

Here's how inodes and path resolution work:

1. Inode Structure:
```v
struct Inode {
mut:
    ino        u64      // Inode number
    parent     u64      // Parent inode number
    mode       u32      // File type and permissions
    size       u64      // Size in bytes
    nlink      u32      // Number of hard links
    uid        u32      // User ID
    gid        u32      // Group ID
    atime      i64      // Access time
    mtime      i64      // Modification time
    ctime      i64      // Change time
    children   map[string]u64  // For directories: filename -> inode number
    data       []u8     // File data or symlink target
}
```

2. Path Resolution (inode to path):
```v
struct InodeFS {
mut:
    inodes map[u64]&Inode
    mutex  sync.Mutex
}

fn (fs InodeFS) get_path(ino u64) ?string {
    if ino == 1 {  // Root inode
        return '/'
    }

    mut path_parts := []string{}
    mut current := ino

    for {
        if current == 1 {
            break
        }

        inode := fs.inodes[current] or { return error('Inode not found') }
        parent_inode := fs.inodes[inode.parent] or { return error('Parent not found') }

        // Find the name of current inode in parent's children
        mut name := ''
        for entry_name, child_ino in parent_inode.children {
            if child_ino == current {
                name = entry_name
                break
            }
        }

        if name == '' {
            return error('Name not found')
        }

        path_parts.prepend(name)
        current = inode.parent
    }

    return '/' + path_parts.join('/')
}
```

3. Path to Inode Resolution:
```v
fn (fs InodeFS) lookup_path(path string) ?u64 {
    if path == '/' {
        return 1  // Root inode
    }

    parts := path.trim_left('/').split('/')
    mut current := u64(1)  // Start at root

    for part in parts {
        current_inode := fs.inodes[current] or { return error('Inode not found') }
        current = current_inode.children[part] or { return error('Entry not found') }
    }

    return current
}
```

4. Complete Example with Directory Operations:
```v
struct InodeFS {
mut:
    inodes     map[u64]&Inode
    next_ino   u64
    mutex      sync.Mutex
}

fn new_inodefs() &InodeFS {
    mut fs := &InodeFS{
        inodes: map[u64]&Inode{}
        next_ino: 2  // 1 is reserved for root
    }

    // Create root inode
    fs.inodes[1] = &Inode{
        ino: 1
        parent: 1
        mode: S_IFDIR | 0o755
        nlink: 2  // . and ..
        children: map[string]u64{}
    }

    return fs
}

fn (mut fs InodeFS) mkdir(parent_ino u64, name string, mode u32) ?u64 {
    fs.mutex.@lock()
    defer { fs.mutex.unlock() }

    parent := fs.inodes[parent_ino] or { return error('Parent not found') }
    if name in parent.children {
        return error('Entry exists')
    }

    new_ino := fs.next_ino
    fs.next_ino++

    // Create new directory inode
    new_inode := &Inode{
        ino: new_ino
        parent: parent_ino
        mode: S_IFDIR | mode
        nlink: 2
        children: map[string]u64{}
    }

    fs.inodes[new_ino] = new_inode
    parent.children[name] = new_ino
    parent.nlink++  // Parent gets new link from child's ".."

    return new_ino
}

fn (mut fs InodeFS) create_file(parent_ino u64, name string, mode u32) ?u64 {
    fs.mutex.@lock()
    defer { fs.mutex.unlock() }

    parent := fs.inodes[parent_ino] or { return error('Parent not found') }
    if name in parent.children {
        return error('Entry exists')
    }

    new_ino := fs.next_ino
    fs.next_ino++

    // Create new file inode
    new_inode := &Inode{
        ino: new_ino
        parent: parent_ino
        mode: S_IFREG | mode
        nlink: 1
        data: []u8{}
    }

    fs.inodes[new_ino] = new_inode
    parent.children[name] = new_ino

    return new_ino
}

// FUSE low-level operation handlers
fn (mut fs InodeFS) lookup(req &fuse_req_t, parent u64, name &char) {
    name_str := unsafe { cstring_to_vstring(name) }
    
    parent_inode := fs.inodes[parent] or {
        C.fuse_reply_err(req, ENOENT)
        return
    }

    child_ino := parent_inode.children[name_str] or {
        C.fuse_reply_err(req, ENOENT)
        return
    }

    child := fs.inodes[child_ino] or {
        C.fuse_reply_err(req, ENOENT)
        return
    }

    mut entry := fuse_entry_param{}
    entry.ino = child_ino
    entry.attr = child.to_stat()
    entry.attr_timeout = 1.0
    entry.entry_timeout = 1.0

    C.fuse_reply_entry(req, &entry)
}
```

Key Concepts:
1. Each inode has a unique number (ino)
2. Directories maintain a mapping of names to child inodes
3. Path resolution requires traversing from root to target
4. Parent references allow backward traversal
5. Special inodes:
   - Root inode (typically 1)
   - "." (current directory)
   - ".." (parent directory)

Would you like me to explain any specific aspect in more detail?