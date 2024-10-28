module scanner

import os
import regex

struct Re_group {
pub:
	start int = -1
	end   int = -1
}

// Removes pub, mut, non-needed code, ...
fn cleaner(code string) !string {
	mut lines := code.split_into_lines()
	mut processed_lines := []string{}
	mut in_function := false
	mut in_struct_or_enum := false

	// Precompile regex patterns for efficiency
	mut pub_line_re := regex.regex_opt(r'^\s*pub\s*(\s+mut\s*)?:')!
	mut struct_enum_start_re := regex.regex_opt(r'(struct|enum)\s+\w+\s*{')!
	mut fn_start_re := regex.regex_opt(r'fn\s+')!

	for mut line in lines {
		line = line.replace('\t', '    ')
		stripped_line := line.trim_space()

		// Skip lines starting with 'pub mut:'
		mut start, mut end := pub_line_re.match_string(stripped_line)
		if start != -1 && end != -1 {
			continue
		}

		// Remove 'pub ' at the start of struct and function lines
		if stripped_line.starts_with('pub ') {
			line = line.trim_left(' ')[4..] // Remove leading spaces and 'pub '
		}

		// Check if we're entering or exiting a struct or enum
		start, end = struct_enum_start_re.match_string(stripped_line)
		if start != -1 && end != -1 {
			in_struct_or_enum = true
			processed_lines << line
		} else if in_struct_or_enum && stripped_line.contains('}') {
			in_struct_or_enum = false
			processed_lines << line
		} else if in_struct_or_enum {
			// Ensure consistent indentation within structs and enums
			processed_lines << line
		} else {
			// Handle function declarations
			fnstart, fnend := fn_start_re.match_string(stripped_line)
			if fnstart != -1 && fnend != -1 {
				if stripped_line.contains('{') {
					// Function declaration and opening brace on the same line
					in_function = true
					processed_lines << line
				} else {
					panic('Accolade needs to be in fn line.\n${line}')
				}
			} else if in_function {
				if stripped_line == '}' {
					// Closing brace of the function
					in_function = false
					processed_lines << '}'
				}
				// Skip all other lines inside the function
			} else {
				processed_lines << line
			}
		}
	}

	return processed_lines.join('\n')
}

fn load(path_ string) !string {
	// walk over directory find all .v files, recursive
	// ignore all imports (import at start of line)
	// ignore all module ... (module at start of line)
	path := os.expand_tilde_to_home(path_)
	if !os.exists(path) {
		panic('The path \'${path}\' does not exist.')
	}
	mut all_code := []string{}
	// Walk over directory recursively
	vfiles := os.walk_ext(path, '.v')
	for file_path in vfiles {
		lines := os.read_lines(file_path)!

		// Filter out import and module lines
		mut filtered_lines := []string{}
		for line in lines {
			if !line.trim_space().starts_with('import') && !line.trim_space().starts_with('module') {
				filtered_lines << line
			}
		}

		all_code << filtered_lines.join('')
	}

	return all_code.join('\n\n')
}

// fn main() {
// 	// from hero_server.lib.openrpc.parser.example import load_example
// 	code := load('~/code/git.ourworld.tf/projectmycelium/hero_server/lib/openrpclib/parser/examples')
// 	// Parse the code
// 	code = cleaner(code)
// 	println(code)
// }
