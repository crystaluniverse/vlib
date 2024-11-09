# OurDB Module

OurDB is a lightweight, efficient key-value database implementation in V that provides data persistence with history tracking capabilities. It's designed for scenarios where you need fast key-value storage with the ability to track changes over time.

## Usage Example

```v

//record_nr_max u32 = 16777216 - 1    // max number of records
//record_size_max u32 = 1024*4        // max record size (4KB default)
//file_size u32 = 500 * (1 << 20)     // file size (500MB default)
//path string                         // storage directory

import crystallib.data.ourdb

mut db := ourdb.new(path:"/tmp/mydb")!

// Store data (note: set() takes []u8 as value)
db.set(1, 'Hello World'.bytes())!

// Retrieve data
data := db.get(1)! // Returns []u8

// Get history
history := db.get_history(1, 5)! // Get last 5 versions

// Delete data
db.delete(1)!
```


## Features

- Efficient key-value storage
- History tracking for values
- Data integrity verification using CRC32
- Support for multiple backend files
- Configurable record sizes and counts
- Memory and disk-based lookup tables

## Architecture

OurDB consists of three main components working together in a layered architecture:

### 1. Frontend (db.v)
- Provides the public API for database operations
- Handles high-level operations (set, get, delete, history)
- Coordinates between lookup and backend components
- Located in `db.v`

### 2. Lookup Table (lookup.v)
- Maps keys to physical locations in the backend storage
- Supports both memory and disk-based lookup tables
- Configurable key sizes for optimization
- Handles sparse data efficiently
- Located in `lookup.v`

### 3. Backend Storage (backend.v)
- Manages the actual data storage in files
- Handles data integrity with CRC32 checksums
- Supports multiple file backends for large datasets
- Implements the low-level read/write operations
- Located in `backend.v`

## File Structure

- `db.v`: Frontend interface providing the public API
- `lookup.v`: Implementation of the lookup table system
- `backend.v`: Low-level data storage implementation
- `factory.v`: Database initialization and configuration
- `db_test.v`: Test suite for verifying functionality

## How It Works

1. **Frontend Operations**
   - When you call `set(key, value)`, the frontend:
     1. Gets the storage location from the lookup table
     2. Passes the data to the backend for storage
     3. Updates the lookup table with any new location

2. **Lookup Table**
   - Maintains a mapping between keys and physical locations
   - Optimizes key size based on maximum record count
   - Can be memory-based for speed or disk-based for large datasets
   - Supports sparse data storage for efficient space usage

3. **Backend Storage**
   - Stores data in one or multiple files
   - Each record includes:
     - Data size
     - CRC32 checksum
     - Previous record location (for history)
     - Actual data
   - Automatically handles file selection and management

## Implementation Details

### Record Format
Each record in the backend storage includes:
- 2 bytes: Data size
- 4 bytes: CRC32 checksum
- 6 bytes: Previous record location
- N bytes: Actual data

### Lookup Table Optimization
The lookup table automatically optimizes its key size based on:
- Total number of records (affects address space)
- Record size and count (determines file splitting)
- Available memory (can switch to disk-based lookup)

### File Management
- Supports splitting data across multiple files when needed
- Each file is limited to 500MB by default (configurable)
- Automatic file selection based on record location
- Files are created as needed with format: `${path}/${file_nr}.db`
