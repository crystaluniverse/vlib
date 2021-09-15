module actionparser

import os
import texttools

enum ParseBlockStatus {
	start
	action
}

enum ParseStatus {
	start
	actionstart // found !! or #!! or //!!, now we need to find action name
	param_name // need to get params out
	param_value_quote // found ' need to find ending '
	param_valua_multiline // busy finding the multiline
	comment // found // or # at end
}

struct ParseResult {
mut:
	actions []ParseAction
}

struct ParseAction {
pub:
	name string
pub mut:
	params []ParseParam
}

struct ParseParam {
pub:
	name  string
	value string
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

// DO NOT CHANGE THE WAY HOW THIS WORKS, THIS HAS BEEN DONE AS A STATEFUL PARSER BY DESIGN
// THIS ALLOWS FOR EASY ADOPTIONS TO DIFFERENT RELIALITIES

pub fn parse(path string) ?ParseResult {
	if !os.exists(path) {
		return error("path: '$path' does not exist, cannot parse.")
	}
	content := os.read_file(path) or { panic('Failed to load file $path') }

	blocks := parse_into_blocks(content) ?

	mut parseresult := ParseResult{}

	parseresult.parse_actions(blocks)

	return parseresult
}

// each block is name of action and the full content behind
fn parse_into_blocks(text string) ?Blocks {
	mut state := ParseBlockStatus.start
	mut blocks := Blocks{}
	mut block := Block{}
	mut pos := 0
	mut line_strip := ''
	mut line2 := ''
	// no need to process files which are not at least 2 chars
	for line_ in text.split_into_lines() {
		line2 = line_
		line2 = line2.replace('\t', '    ')
		// println("line: '$line2'")
		line_strip = line2.trim_space()
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
	println(blocks.blocks[13].content)
	return blocks
}

fn (mut block Block) clean() {
	block.name = block.name.trim_space().to_lower()
	block.content = texttools.dedent(block.content) // remove leading space
}

fn (mut result ParseResult) parse_block(block Block) {
	params := texttools.text_to_params(block.content) or { panic(err) }

	mut action := ParseAction{
		name: block.name
	}

	for param in params.params {
		action.params << ParseParam{
			name: param.key
			value: param.value
		}
	}

	result.actions << action
}

fn (mut results ParseResult) parse_actions(blocks Blocks) {
	for block in blocks.blocks {
		results.parse_block(block)
	}
}
