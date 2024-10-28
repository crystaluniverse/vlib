module scanner

import regex
import json

enum CodeType {
	struct_
	enum_
	function
}

struct CodeBlock {
	code_type CodeType
	comments  []string
	block     string
}

fn splitter(code string) []CodeBlock {
	lines := code.split_into_lines()
	mut result := []CodeBlock{}
	mut current_block := CodeBlock{}
	mut current_comments := []string{}

	for line in lines {
		line = line.replace('\t', '    ')
		stripped_line := line.trim_space()

		if stripped_line.starts_with('//') {
			current_comments << stripped_line[2..].trim_space()
		} else if stripped_line.starts_with('struct ') {
			if current_block.block != '' {
				result << current_block
			}
			current_block = CodeBlock{
				code_type: .struct_
				comments: current_comments
				block: line
			}
			current_comments.clear()
		} else if stripped_line.starts_with('enum ') {
			if current_block.block != '' {
				result << current_block
			}
			current_block = CodeBlock{
				code_type: .enum_
				comments: current_comments
				block: line
			}
			current_comments.clear()
		} else if stripped_line.starts_with('fn ') {
			if current_block.block != '' {
				result << current_block
			}
			current_block = CodeBlock{
				code_type: .function
				comments: current_comments
				block: line.all_before('{').trim_space()
			}
			current_comments.clear()
		} else if current_block.block != '' {
			if current_block.code_type == .struct_ && stripped_line == '}' {
				current_block.block += '\n' + line
				result << current_block
				current_block = CodeBlock{}
			} else if current_block.code_type == .enum_ && stripped_line == '}' {
				current_block.block += '\n' + line
				result << current_block
				current_block = CodeBlock{}
			} else if current_block.code_type in [.struct_, .enum_] {
				current_block.block += '\n' + line
			}
		}
	}

	if current_block.block != '' {
		result << current_block
	}

	return result
}

// fn main() {
// 	code := load('/root/code/git.ourworld.tf/projectmycelium/hero_server/lib/openrpclib/parser/examples')
// 	cleaned_code := cleaner(code)
// 	parsed_code := splitter(cleaned_code)
// 	for item in parsed_code {
// 		println('Type: ${item.code_type}')
// 		println('Comments: ${item.comments}')
// 		println('Block:\n${item.block}')
// 		println('-'.repeat(50))
// 	}
// }
