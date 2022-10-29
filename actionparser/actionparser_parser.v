module actionparser

import os
import freeflowuniverse.crystallib.params
import freeflowuniverse.crystallib.texttools

enum ParseBlockStatus {
	start
	action
}

enum ParseStatus {
	start
	actionstart // found !! or #!! or //!!, now we need to find action name
	param_name // need to get params out
	param_value_quote // found ' need to find ending '
	param_value_multiline // busy finding the multiline
	comment // found // or # at end
}

// first step is to get the blocks out
struct Blocks {
mut:
	blocks []Block
}

struct Block {
mut:
	name    string
	content string
}

// TODO/ add recursive
// fn file_includes(path string) ?string {
// 	path0 := pathtools.get(path)
// 	content := path0.read()?
// 	out=[]string{}
// 	for line in content.split_into_lines(){
// 		if line.starts_with("!!include"){
// 			//now we can do the include
// 			params := params.text_to_params(line.all_after_first(" ")) or { panic(err) }
// 			path_to_include := params.get_path("path")? //checks it exists
// 			path_included := pathtools.get(path_to_include)?
// 			content := path_included.read()?
// 			for line in content.split_into_lines(){
// 				out << line
// 			}
// 			continue
// 		}
// 		out << line
// 	}
// }

// DO NOT CHANGE THE WAY HOW THIS WORKS, THIS HAS BEEN DONE AS A STATEFUL PARSER BY DESIGN
// THIS ALLOWS FOR EASY ADOPTIONS TO DIFFERENT RELIALITIES

pub fn (mut parser ActionsParser) file_parse(path string) ? {
	if !os.exists(path) {
		return error("path: '$path' does not exist, cannot parse.")
	}
	content := os.read_file(path) or { panic('Failed to load file $path') }
	parser.text_parse(content)?
}

fn (mut parser ActionsParser) text_parse(content string) ? {
	blocks := parse_into_blocks(content)?
	parser.parse_actions(blocks)
}

// each block is name of action and the full content behind
fn parse_into_blocks(text string) ?Blocks {
	mut state := ParseBlockStatus.start
	mut blocks := Blocks{}
	mut block := Block{}
	mut pos := 0
	mut line2 := ''
	// no need to process files which are not at least 2 chars
	for line_ in text.split_into_lines() {
		line2 = line_
		line2 = line2.replace('\t', '    ')
		// println("line: '$line2'")
		if state == ParseBlockStatus.action {
			if line2.starts_with(' ') || line2 == '' {
				// starts with tab or space, means block continues
				block.content += '\n'
				block.content += line2
			} else {
				// means block stops
				state = ParseBlockStatus.start
				// add found block
				block.clean()
				blocks.blocks << block
				block = Block{} // new block
			}
		}
		if state == ParseBlockStatus.start {
			if line2.starts_with('!!') || line2.starts_with('#!!') || line2.starts_with('//!!') {
				state = ParseBlockStatus.action
				pos = line2.index(' ') or { 0 }
				if pos > 0 {
					block.name = line2[0..pos]
					block.content = line2[pos..]
				} else {
					block.name = line2.trim_space() // means no arguments
				}
				block.name = block.name.trim_space().trim_left('#/!')
			}
			continue
		}
	}
	if block.name.len > 0 {
		// add last block to it
		block.clean()
		blocks.blocks << block
	}
	// println(blocks.blocks[13].content)
	return blocks
}

fn (mut block Block) clean() {
	block.name = block.name.trim_space().to_lower()
	block.content = texttools.dedent(block.content) // remove leading space
}

fn (mut parser ActionsParser) parse_block(block Block) {
	params := params.text_to_params(block.content) or { panic(err) }

	mut action := Action{
		name: block.name
		params: params
	}
	parser.actions << action
}

fn (mut parser ActionsParser) parse_actions(blocks Blocks) {
	for block in blocks.blocks {
		parser.parse_block(block)
	}
}
