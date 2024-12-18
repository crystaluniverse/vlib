


import os
import regex

struct Re_group {
pub:
	start int = -1
	end   int = -1
}

// Removes pub, mut, non-needed code, ...
fn cleaner(code string) !string {

	lines := code.split_into_lines()
	mut processed_lines := []string{}
	mut in_function := false
	mut in_struct_or_enum := false

  // Precompile regex patterns for efficiency
  mut pub_line_re := regex.regex_opt(r'^\s*pub\s*(\s+mut\s*)?:')!
  mut pub_prefix_re := regex.regex_opt(r'^\s*pub\s+')!
  mut struct_enum_start_re := regex.regex_opt(r'(struct|enum)\s+\w+\s*{')!
  mut fn_start_re := regex.regex_opt(r'fn\s+')!

	for line in lines {
		mut line2 := line.replace('\t', '    ')
		stripped_line := line2.trim_space()

		// Skip lines starting with 'pub mut:'
		if pub_line_re.match_string(stripped_line) != -1 -1 {
			continue
		}

		// Remove 'pub ' at the start of struct and function lines
		line2 = line2.replace_with_fn(pub_prefix_re, fn (re regex.RE, line string, start int, end int) string {
			return ''
		})

		// Check if we're entering or exiting a struct or enum
		if struct_enum_start_re.match_string(stripped_line) != -1 -1 {
			in_struct_or_enum = true
			processed_lines << line2
		} else if in_struct_or_enum && '}' in stripped_line {
			in_struct_or_enum = false
			processed_lines << line2
		} else if in_struct_or_enum {
			// Ensure consistent indentation within structs and enums
			processed_lines << line2
		} else {
			// Handle function declarations
			if fn_start_re.match_string(stripped_line) != -1 -1 {
				if '{' in stripped_line {
					// Function declaration and opening brace on the same line
					in_function = true
					processed_lines << line2
				} else {
					panic('Accolade needs to be in fn line.\n${line2}')
				}
			} else if in_function {
				if stripped_line == '}' {
					// Closing brace of the function
					in_function = false
					processed_lines << '}'
				}
				// Skip all other lines inside the function
			} else {
				processed_lines << line2
			}
		}
	}
	return processed_lines.join('\n')
}

fn load(path string) string {
	// walk over directory find all .v files, recursive
	// ignore all imports (import at start of line)
	// ignore all module ... (module at start of line)
	path = os.expand_path(path)
	if !os.exists(path) {
		panic('The path \'${path}\' does not exist.')
	}
	mut all_code := []string{}
	// Walk over directory recursively
	os.walk_ext(path, '.v', fn (path string, files []string) {
		for file in files {
			file_path := os.join_path(path, file)
			lines := os.read_lines(file_path) or { panic(err) }

			// Filter out import and module lines
			mut filtered_lines := []string{}
			for line in lines {
				if !line.trim_space().starts_with(['import', 'module']) {
					filtered_lines << line
				}
			}

			all_code << filtered_lines.join('')
		}
	})
	return all_code.join('\n\n')
}

fn main() {
	// from hero_server.lib.openrpc.parser.example import load_example
	code := load('~/code/git.ourworld.tf/projectmycelium/hero_server/lib/openrpclib/parser/examples')
	// Parse the code
	code = cleaner(code)
	println(code)
}
