# Pathlib Module

The pathlib module provides a robust way to handle file system operations. Here's a comprehensive overview of how to use it:

## 1. Basic Path Creation

```v
import freeflowuniverse.crystallib.core.pathlib

// Get a basic path object
mut path := pathlib.get('/some/path')

// Create a directory (with parent dirs)
mut dir := pathlib.get_dir(
    path: '/some/dir'
    create: true
)!

// Create/get a file
mut file := pathlib.get_file(
    path: '/some/file.txt'
    create: true
)!
```

## 2. Path Properties and Operations

```v
// Get various path forms
abs_path := path.absolute()      // Full absolute path
real_path := path.realpath()     // Resolves symlinks
short_path := path.shortpath()   // Uses ~ for home dir

// Get path components
name := path.name()              // Filename with extension
name_no_ext := path.name_no_ext() // Filename without extension
dir_path := path.path_dir()      // Directory containing the path

// Check path properties
if path.exists() { /* exists */ }
if path.is_file() { /* is file */ }
if path.is_dir() { /* is directory */ }
if path.is_link() { /* is symlink */ }
```

## 3. Common File Operations

```v
// Empty a directory
mut dir := pathlib.get_dir(
    path: '/some/dir'
    empty: true
)!

// Delete a path
mut path := pathlib.get_dir(
    path: '/path/to/delete'
    delete: true
)!

// Get working directory
mut wd := pathlib.get_wd()
```

## Features

The module handles common edge cases:
- Automatically expands ~ to home directory
- Creates parent directories as needed
- Provides proper error handling with V's result type
- Checks path existence and type
- Handles both absolute and relative paths

## Path Object Structure

Each Path object contains:
- `path`: The actual path string
- `cat`: Category (file/dir/link)
- `exist`: Existence status

This provides a safe and convenient API for all file system operations in V.
