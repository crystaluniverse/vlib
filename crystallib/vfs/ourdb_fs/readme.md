# a OurDBFS: filesystem interface on top of ourbd

The OurDBFS manages files and directories using unique identifiers (u32) as keys and binary data ([]u8) as values.


## Architecture

### Storage Backend (the ourdb)

- Uses a key-value store where keys are u32 and values are []u8 (bytes)
- Stores both metadata and file data in the same database
- Example usage of underlying database:

```v
import crystallib.data.ourdb

mut db_meta := ourdb.new(path:"/tmp/mydb")!

// Store data
db_meta.set(1, 'Hello World'.bytes())!

// Retrieve data
data := db_meta.get(1)! // Returns []u8

// Delete data
db_meta.delete(1)!
```

### Core Components

#### 1. Common Metadata (common.v)

All filesystem entries (files and directories) share common metadata:
```v
pub struct Metadata {
    id          u32    // unique identifier used as key in DB
    name        string // name of file or directory
    file_type   FileType
    size        u64
    created_at  i64    // unix epoch timestamp
    modified_at i64    // unix epoch timestamp
    accessed_at i64    // unix epoch timestamp
    mode        u32    // file permissions
    owner       string
    group       string
}
```

#### 2. Files (file.v)
Files are represented as:
```v
pub struct File {
    metadata    Metadata  // Common metadata
    parent_id   u32      // ID of parent directory
    data_blocks []u32    // List of block IDs containing file data
}
```

#### 3. Directories (directory.v)
Directories are represented as:
```v
pub struct Directory {
    metadata    Metadata  // Common metadata
    parent_id   u32      // ID of parent directory
    children    []u32    // List of child IDs (files and directories)
}
```

#### 4. Data Storage (data.v)
File data is stored in blocks:
```v
pub struct DataBlock {
    id    u32   // Block ID
    data  []u8  // Actual data content
    size  u32   // Size of data in bytes
    next  u32   // ID of next block (0 if last block)
}
```

### Features

1. **Hierarchical Structure**
   - Files and directories are organized in a tree structure
   - Each entry maintains a reference to its parent directory
   - Directories maintain a list of child entries

2. **Metadata Management**
   - Comprehensive metadata tracking including:
     - Creation, modification, and access timestamps
     - File permissions
     - Owner and group information
     - File size and type

3. **File Operations**
   - File creation and deletion
   - Data block management for file content
   - Future support for read/write operations

4. **Directory Operations**
   - Directory creation and deletion
   - Listing directory contents (recursive and non-recursive)
   - Child management

### Implementation Details

1. **File Types**
```v
pub enum FileType {
    file
    directory
    symlink
}
```

2. **Data Block Management**
   - File data is split into blocks
   - Blocks are linked using the 'next' pointer
   - Each block has a unique ID for retrieval

3. **Directory Traversal**
   - Supports both recursive and non-recursive listing
   - Uses child IDs for efficient navigation

### TODO Items


> TODO: what is implemented and what not?

1. Directory Implementation
   - Implement recursive listing functionality
   - Proper cleanup of children during deletion
   - ID generation system

2. File Implementation
   - Proper cleanup of data blocks
   - Data block management system
   - Read/Write operations

3. General Improvements
   - Transaction support
   - Error handling
   - Performance optimizations
   - Concurrency support






use @encoder dir to see how to encode/decode

make an efficient encoder for Directory
add a id u32 to directory this will be the key of the keyvalue stor used

try to use as few as possible bytes when doing the encoding

the first byte is a version nr, so we know if we change the encoding format we can still decode

we will only store directories