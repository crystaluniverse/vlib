module scanner

import os

fn includes_process_text(text string) map[string]string {
	lines := text.split('\n')
	mut result := map[string]string{}
	mut current_block := ''
	mut current_content := []string{}

	for line in lines {
		stripped_line := line.trim_space()
		if stripped_line.starts_with('<') && stripped_line.ends_with('>')
			&& !stripped_line.starts_with('<END') {
			if current_block != '' {
				panic('should not come here, there needs to be <END> after a block.\n${line}')
			}
			current_block = stripped_line[1..stripped_line.len - 1] // Remove '<' and '>'
			current_content.clear()
		} else if stripped_line == '<END>' {
			if current_block != '' {
				result[current_block] = current_content.join('\n').trim_right('\n')
				current_block = ''
				current_content.clear()
			}
		} else if current_block != '' {
			current_content << line
		}
	}

	if current_block != '' {
		panic('should not come here, there needs to be <END> after a block.\n${current_block}')
		result[current_block] = current_content.join('\n').trim_right('\n')
	}

	return result
}

fn include_process_directory(path string) !map[string]string {
	mut expanded_path := os.expand_tilde_to_home(path)
	if !os.exists(expanded_path) {
		return error("The path '${expanded_path}' does not exist.")
	}

	mut all_blocks := map[string]string{}
	vfiles := os.walk_ext(expanded_path, '.v')
	for file_path in vfiles {
		if os.file_name(file_path).starts_with('include_') {
			content := os.read_file(file_path)!
			blocks := includes_process_text(content)
			for k, v in blocks {
				all_blocks[k] = v
			}
		}
	}
	return all_blocks
}

fn include_process_text(input_text string, block_dict map[string]string) string {
	lines := input_text.split('\n')
	mut result_lines := []string{}

	for line in lines {
		stripped_line := line.trim_space()
		if stripped_line.starts_with('//include<') && stripped_line.ends_with('>') {
			key := stripped_line[10..stripped_line.len - 1].to_upper()
			if key in block_dict {
				result_lines << block_dict[key]
			} else {
				result_lines << "// ERROR: Block '${key}' not found in dictionary"
			}
		} else {
			result_lines << line
		}
	}

	return result_lines.join('\n')
}

// fn main() {
// 	// Example usage
// 	input_text := "
// <BASE>
//     oid string //is unique id for user in a circle, example=a7c  *
//     name string //short name for swimlane'
//     time_creation int //time when signature was created, in epoch  example=1711442827 *
//     comments []string //list of oid's of comments linked to this story
// <END>

// <MYNAME>
// this is my name, one line only
// <END>
// "

// 	//parsed_blocks := include_parse_blocks(input_text)

// 	includes_dict := include_process_directory('~/code/git.ourworld.tf/projectmycelium/hero_server/lib/openrpclib/parser/examples')

// 	for key, value in includes_dict {
// 		println('${key}:')
// 		println(value)
// 		println('')  // Add a blank line between blocks for readability
// 	}

// 	input_text2 := '
// //we didn\'t do anything for comments yet
// //
// //this needs to go to description in openrpc spec
// //
// @[rootobject]
// struct Story {
//     //include<BASE>
//     content string //description of the milestone example="this is example content which gives more color" *
//     owners []string //list of users (oid) who are the owners of this project example="10a,g6,aa1" *
//     notifications []string //list of users (oid) who want to be informed of changes of this milestone example="ad3"
//     deadline int //epoch deadline for the milestone example="1711442827" *
//     projects []string //link to a projects this story belongs too
//     milestones []string //link to the mulestones this story belongs too
// }
// '

// 	result := include_process_text(input_text2, includes_dict)
// 	println(result)
// }
