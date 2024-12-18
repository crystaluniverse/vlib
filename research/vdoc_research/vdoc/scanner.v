module vdoc

import os
import freeflowuniverse.crystallib.ui.console

// is_v_source_file checks if a file is a valid V source file
fn is_v_source_file(path string) bool {
	console.print_debug('DEBUG: Checking if file is V source: ${path}')
	if !path.ends_with('.v') {
		console.print_debug('DEBUG: Skipping non-V file: ${path}')
		return false
	}
	// Skip test files and temporary files
	if path.ends_with('_test.v') || path.contains('.tmp.v') || path.contains('cache') {
		console.print_debug('DEBUG: Skipping test/temp/cache file: ${path}')
		return false
	}
	console.print_debug('DEBUG: Valid V source file found: ${path}')
	return true
}

// make_relative makes a path relative to the scan root
fn (factory VDocFactory) make_relative(path string) string {
	relative_path := path.replace(factory.scan_root + '/', '')
	console.print_debug('DEBUG: Converting path to relative: ${path} -> ${relative_path}')
	return relative_path
}

// scan recursively processes a directory for .v and .md files
pub fn (mut factory VDocFactory) scan(dir_path string) ! {
	console.print_debug('DEBUG: Starting initial scan of: ${dir_path}')
	factory.scan_with_depth(dir_path, 0, []string{}) or { return error(err.msg()) }
}

// scan_with_depth recursively processes a directory with depth tracking and cycle detection
fn (mut factory VDocFactory) scan_with_depth(dir_path string, depth int, visited []string) ! {
	console.print_debug('DEBUG: Entering scan_with_depth for: ${dir_path} at depth ${depth}')

	// Prevent excessive recursion
	if depth > 20 {
		return error('Maximum directory depth reached at: ${dir_path}')
	}

	// Get canonical path to detect cycles
	real_path := os.real_path(dir_path)
	console.print_debug('DEBUG: Real path: ${real_path}')

	// Check for directory cycles
	if real_path in visited {
		return error('DEBUG: Directory cycle detected at: ${dir_path}')
	}

	if factory.scan_root == '' {
		factory.scan_root = dir_path
		console.print_debug('DEBUG: Set scan root to: ${dir_path}')
	}

	// Get all files in the directory
	items := os.ls(dir_path)!
	console.print_debug('DEBUG: Found ${items.len} items in directory')

	mut current_module := VModule{
		path:    factory.make_relative(dir_path)
		files:   []VFile{}
		md_docs: []MDoc{}
	}
	console.print_debug('DEBUG: Created new module for path: ${current_module.path}')

	// Track visited directories for cycle detection
	mut new_visited := visited.clone()
	new_visited << real_path

	for item in items {
		full_path := os.join_path(dir_path, item)
		console.print_debug('DEBUG: Processing item: ${item} at ${full_path}')

		if os.is_dir(full_path) {
			// Skip certain directories
			base := os.base(full_path)
			if base.starts_with('.') || base.starts_with('_') || base == 'node_modules'
				|| base == 'target' {
				console.print_debug('DEBUG: Skipping directory: ${base}')
				continue
			}
			// Recursively process subdirectories with increased depth
			console.print_debug('DEBUG: Recursively scanning subdirectory: ${full_path}')
			factory.scan_with_depth(full_path, depth + 1, new_visited)!
			continue
		}

		// Process files based on extension
		if is_v_source_file(full_path) {
			console.print_debug('DEBUG: Processing V source file: ${full_path}')
			content := os.read_file(full_path) or {
				console.print_debug('DEBUG: Error reading V file ${full_path}: ${err}')
				eprintln('Error reading V file ${full_path}: ${err}')
				continue
			}
			mut v_file := VFile{
				path:    factory.make_relative(full_path)
				content: content
			}
			console.print_debug('DEBUG: Created VFile object for: ${v_file.path}')

			// Parse the V file immediately after creation
			console.print_debug('DEBUG: Starting parse of V file: ${v_file.path}')
			v_file.parse(mut current_module)!
			console.print_debug('DEBUG: Successfully parsed V file: ${v_file.path} (found ${v_file.structs.len} structs)')
			current_module.files << v_file
			console.print_debug('DEBUG: Added V file to current module')
		} else if item.ends_with('.md') {
			console.print_debug('DEBUG: Processing markdown file: ${full_path}')
			// Read markdown file
			content := os.read_file(full_path) or {
				console.print_debug('DEBUG: Error reading markdown file ${full_path}: ${err}')
				eprintln('Error reading markdown file ${full_path}: ${err}')
				continue
			}
			md_doc := MDoc{
				path:    factory.make_relative(full_path)
				content: content
			}
			current_module.md_docs << md_doc
			console.print_debug('DEBUG: Added markdown file to current module')
		}
	}

	// Only add module if it contains any files
	if current_module.files.len > 0 || current_module.md_docs.len > 0 {
		console.print_debug('DEBUG: Adding module to factory: ${current_module.path} (${current_module.files.len} V files, ${current_module.md_docs.len} MD files)')
		factory.modules << current_module
	} else {
		console.print_debug('DEBUG: Skipping empty module: ${current_module.path}')
	}
}
