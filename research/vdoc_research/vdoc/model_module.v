module vdoc

import strings

// VModule represents a collection of V and markdown files in a directory
@[heap]
pub struct VModule {
pub mut:
	path    string // relative path from scan root
	files   []VFile
	md_docs []MDoc
}

// find_struct returns a struct by name if it exists in any file in the module
pub fn (mod VModule) find_struct(name string) ?&VStruct {
	for file in mod.files {
		for i, struct_ in file.structs {
			if struct_.name == name {
				return &file.structs[i]
			}
		}
	}
	return none
}

// exists_struct checks if a struct exists by name in any file in the module
pub fn (mod VModule) exists_struct(name string) bool {
	return mod.find_struct(name) != none
}

// find_method returns a method by name if it exists in any struct in any file in the module
pub fn (mod VModule) find_method(name string) ?&VStructMethod {
	for file in mod.files {
		for struct_ in file.structs {
			for i, method in struct_.methods {
				if method.name == name {
					return &struct_.methods[i]
				}
			}
		}
	}
	return none
}

// exists_method checks if a method exists by name in any struct in any file in the module
pub fn (mod VModule) exists_method(name string) bool {
	return mod.find_method(name) != none
}

// str returns a markdown formatted string representation of the module
pub fn (mod VModule) str() string {
	mut sb := strings.new_builder(1000)
	sb.writeln('# Module: ${mod.path}\n')

	// V Files section
	sb.writeln('## V Files\n')
	for file in mod.files {
		sb.writeln('* ${file.path}')

		// List structs in the file
		if file.structs.len > 0 {
			sb.writeln('\n### Structs\n')
			for struct_ in file.structs {
				sb.writeln('#### ${struct_.name}\n')
				if struct_.properties.len > 0 {
					sb.writeln('Properties:')
					for prop in struct_.properties {
						mut prop_str := '* ${prop.name}'
						if prop.type_ != '' {
							prop_str += ' (${prop.type_})'
						}
						if prop.default_val != '' {
							prop_str += ' = ${prop.default_val}'
						}
						if prop.comments != '' {
							prop_str += ' // ${prop.comments}'
						}
						sb.writeln(prop_str)
					}
					sb.writeln('')
				}
				if struct_.methods.len > 0 {
					sb.writeln('Methods:')
					for method in struct_.methods {
						sb.writeln('* ${method.name}(${method.args})')
					}
					sb.writeln('')
				}
			}
		}
	}

	// Markdown docs section
	if mod.md_docs.len > 0 {
		sb.writeln('## Documentation Files\n')
		for doc in mod.md_docs {
			sb.writeln('* ${doc.path}')
		}
	}

	return sb.str()
}
