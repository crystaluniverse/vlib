#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import v.doc
import v.ast

// MarkdownDoc represents a markdown document with its path and content
struct MarkdownDoc {
mut:
    path    string
    content string
}

// VDocFactory holds documentation for both V and Markdown files
struct VDocFactory {
mut:
    docs         []doc.Doc
    markdown_docs []MarkdownDoc
}

// create_factory initializes a new VDocFactory
fn create_factory() VDocFactory {
    return VDocFactory{
        docs: []doc.Doc{}
        markdown_docs: []MarkdownDoc{}
    }
}

// process_dir recursively processes a directory for .v and .md files
fn (mut factory VDocFactory) process_dir(dir_path string) ! {
    // Get all files in the directory
    items := os.ls(dir_path) or { return error('Failed to list directory: ${err}') }
    
    for item in items {
        full_path := os.join_path(dir_path, item)
        
        if os.is_dir(full_path) {
            // Recursively process subdirectories
            factory.process_dir(full_path) or { return error('Failed to process directory: ${err}') }
            continue
        }
        
        // Process files based on extension
        if item.ends_with('.v') {
            // Parse V file using v.doc
            mut d := doc.Doc{
                base_path: full_path
                table: ast.new_table()
            }
            d.generate() or { 
                eprintln('Error processing V file $full_path: $err')
                continue
            }
            factory.docs << d
        } else if item.ends_with('.md') {
            // Read markdown file
            content := os.read_file(full_path) or {
                eprintln('Error reading markdown file $full_path: $err')
                continue
            }
            md_doc := MarkdownDoc{
                path: full_path
                content: content
            }
            factory.markdown_docs << md_doc
        }
    }
}

mut factory := create_factory()

// Process the directory
factory.process_dir("/Users/despiegk1/code/github/freeflowuniverse/crystallib/crystallib") or { return error('Failed to process root directory: ${err}') }

// Print summary
println('Documentation processing complete:')
println('Found ${factory.docs.len} V files')
println('Found ${factory.markdown_docs.len} Markdown files')

// Here you can add additional processing of the collected documentation
// For example, generating HTML, creating indexes, etc.
