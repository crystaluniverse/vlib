// This script walks through directories recursively looking for .collections files
// and extracts their collection names from the file content.
import os

fn main() {
	// Walk through all directories recursively starting from current directory ('.')
	os.walk('.', fn (path string) {
		// Check each file in the current directory
		if path.ends_with('.collections') {
			println('Processing: ${path}')
			collection_name := get_collection_name(path)
			println('Collection name: ${collection_name}')
			// ... do something with the collection_name
		}
	})
}

// get_collection_name reads a file and extracts the collection name from it.
// If the file is empty or doesn't contain a name field, returns the base filename.
fn get_collection_name(filepath string) string {
	// Read the file contents, return base filename if reading fails
	mut contents := os.read_file(filepath) or { return os.base(filepath) }
	if contents.len == 0 {
		return os.base(filepath)
	}
	
	// Look for a line starting with 'name:' and extract the value
	lines := contents.split('\n')
	for line in lines {
		if line.trim().starts_with('name:') {
			return line.trim()[5..].trim() // Extract text after "name:"
		}
	}
	
	// Return base filename if no name field found
	return os.base(filepath)
}
