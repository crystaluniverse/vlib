module vdoc

import freeflowuniverse.crystallib.ui.console

// parse_vfile parses a V source file and extracts all structs and functions
pub fn (mut vfile VFile) parse(mut vmodule VModule) ! {
	console.print_debug_title('VDoc Parser', 'Starting to parse file: ${vfile.path}')
	lines := vfile.content.split_into_lines()
	mut comment_buffer := ''

	for i := 0; i < lines.len; i++ {
		line := lines[i].trim_space()

		// Skip empty lines
		if line == '' {
			continue
		}

		// Handle comments
		if line.starts_with('//') {
			comment_buffer += line[2..].trim_space() + '\n'
			continue
		}

		// Parse struct declaration
		if line.starts_with('pub struct') || line.starts_with('struct') {
			mut struct_name := ''
			if line.starts_with('pub') {
				struct_name = line[11..].split('{')[0].trim_space()
			} else {
				struct_name = line[7..].split('{')[0].trim_space()
			}

			console.print_debug_title('Struct Found', 'Parsing struct: ${struct_name}')

			mut new_struct := VStruct{
				name:       struct_name
				vmodule:    vmodule
				comments:   comment_buffer
				properties: []VStructProperty{}
				methods:    []VStructMethod{}
			}
			comment_buffer = ''

			// Parse struct properties until closing brace
			mut j := i + 1
			for j < lines.len {
				prop_line := lines[j].trim_space()

				// Handle pub/pub mut sections
				if prop_line == 'pub:' || prop_line == 'pub mut:' {
					j++
					continue
				}

				if prop_line == '}' {
					break
				}

				if prop_line != '' && !prop_line.starts_with('//') {
					mut prop_comment := ''
					mut prop_line_clean := prop_line

					// Extract inline comment if present
					if prop_line.contains('//') {
						parts := prop_line.split('//')
						prop_line_clean = parts[0].trim_space()
						prop_comment = parts[1].trim_space()
					}

					// Split the line into parts
					prop_parts := prop_line_clean.split(' ')
					if prop_parts.len >= 2 {
						mut prop_name := ''
						mut prop_type := ''
						mut default_val := ''

						// Handle property with default value
						if prop_line_clean.contains('=') {
							value_parts := prop_line_clean.split('=')
							prop_def := value_parts[0].trim_space().split(' ')
							prop_name = prop_def[0].trim_space()
							prop_type = prop_def[1..].join(' ').trim_space()
							default_val = value_parts[1].trim_space()
						} else {
							// Handle property without default value
							prop_name = prop_parts[0].trim_space()
							prop_type = prop_parts[1..].join(' ').trim_space()
						}

						console.print_debug('Found property: ${prop_name} of type: ${prop_type} with default: ${default_val}')

						mut properties := new_struct.properties.clone()
						properties << VStructProperty{
							vmodule:     &new_struct
							name:        prop_name
							type_:       prop_type
							comments:    prop_comment
							default_val: default_val
						}
						new_struct.properties = properties
					}
				}
				j++
			}
			i = j

			vfile.structs << new_struct
			continue
		}

		// Parse methods
		if line.starts_with('pub fn (') || line.starts_with('fn (') {
			mut method_start := 0
			if line.starts_with('pub') {
				method_start = 7
			} else {
				method_start = 3
			}

			// Extract receiver type
			receiver := line[method_start + 1..].split_nth(')', 2)[0]
			receiver_type := receiver.split(' ')[1].trim_space()

			console.print_debug_title('Method Found', 'Parsing method for type: ${receiver_type}')

			// Find matching struct
			mut parent_struct := VStruct{
				name:       ''
				vmodule:    vmodule
				comments:   ''
				properties: []VStructProperty{}
				methods:    []VStructMethod{}
			}
			mut found := false
			for struct_ in vfile.structs {
				if struct_.name == receiver_type {
					parent_struct = struct_
					found = true
					break
				}
			}

			if !found {
				console.print_debug('No matching struct found for method with receiver type: ${receiver_type}')
				continue // Skip if no matching struct found
			}

			// Extract method name and signature
			method_sig := line[method_start..].split_nth(')', 2)[1].trim_space()
			method_name := method_sig.split('(')[0].trim_space()

			console.print_debug('Method signature: ${method_sig}')

			mut method := VStructMethod{
				name:            method_name
				comments:        comment_buffer
				args:            []VStructMethodArg{}
				kwargs:          []VStructMethodKWArg{}
				result:          []VStructMethodResult{}
				vstruct_pointer: &parent_struct
			}

			// Parse arguments
			args_str := method_sig.split('(')[1].split(')')[0].trim_space()
			if args_str != '' {
				console.print_debug('Parsing arguments: ${args_str}')
				args := args_str.split(',')
				for param in args {
					param_parts := param.trim_space().split(' ')
					if param.contains('=') { // keyword argument
						mut kwargs := method.kwargs.clone()
						kwargs << VStructMethodKWArg{
							name:           param_parts[0]
							default_val:    param.split('=')[1].trim_space()
							method_pointer: &method
						}
						method.kwargs = kwargs
						console.print_debug('Found keyword argument: ${param_parts[0]}')
					} else { // regular argument
						mut method_args := method.args.clone()
						method_args << VStructMethodArg{
							name:           param_parts[0]
							method_pointer: &method
						}
						method.args = method_args
						console.print_debug('Found regular argument: ${param_parts[0]}')
					}
				}
			}

			// Parse return type
			if method_sig.contains('!') {
				console.print_debug('Return type: error union (!)')
				mut results := method.result.clone()
				results << VStructMethodResult{
					canerror:       true
					name:           []string{}
					type_:          []string{}
					method_pointer: &method
				}
				method.result = results
			} else if method_sig.contains('?') {
				console.print_debug('Return type: optional (?)')
				mut results := method.result.clone()
				results << VStructMethodResult{
					optional:       true
					name:           []string{}
					type_:          []string{}
					method_pointer: &method
				}
				method.result = results
			} else if method_sig.contains(')') && method_sig.split(')')[1].trim_space() != '' {
				return_type := method_sig.split(')')[1].trim_space()
				console.print_debug('Return type: ${return_type}')
				mut results := method.result.clone()
				results << VStructMethodResult{
					name:           [return_type]
					type_:          [return_type]
					method_pointer: &method
				}
				method.result = results
			}

			// Add method to struct
			mut methods := parent_struct.methods.clone()
			methods << method
			parent_struct.methods = methods

			comment_buffer = ''
			continue
		}

		// Reset comment buffer if line is not a comment and we didn't use it
		comment_buffer = ''
	}
}
