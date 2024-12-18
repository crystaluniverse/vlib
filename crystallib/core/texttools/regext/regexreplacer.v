module regext

import freeflowuniverse.crystallib.core.texttools
import regex
import freeflowuniverse.crystallib.ui.console
import os

pub struct ReplaceInstructions {
pub mut:
	instructions []ReplaceInstruction
}

pub struct ReplaceInstruction {
pub:
	regex_str    string
	find_str     string
	replace_with string
pub mut:
	regex regex.RE
}

fn (mut self ReplaceInstructions) get_regex_queries() []string {
	mut res := []string{}
	for i in self.instructions {
		res << i.regex.get_query()
	}
	return res
}

// rewrite a filter string to a regex .
// each char will be checked for in lower case as well as upper case (will match both) .
// will only look at ascii .
//'_- ' will be replaced to match one or more spaces .
// the returned result is a regex string
pub fn regex_rewrite(r string) !string {
	r2 := r.to_lower()
	mut res := []string{}
	for ch in r2 {
		mut c := ch.ascii_str()
		if 'abcdefghijklmnopqrstuvwxyz'.contains(c) {
			char_upper := c.to_upper()
			res << '[' + c + char_upper + ']'
		} else if '0123456789'.contains(c) {
			res << c
		} else if '_- '.contains(c) {
			// res << r"\[\\s _\\-\]*"
			res << r' *'
		} else if '\'"'.contains(c) {
			continue
		} else if '^&![]'.contains(c) {
			return error('cannot rewrite regex: ${r}, found illegal char ^&![]')
		}
	}
	return res.join('')
	//+r"[\\n \:\!\.\?;,\\(\\)\\[\\]]"
}

// regex string see https://github.com/vlang/v/blob/master/vlib/regex/README.md .
// find_str is a normal search (text) .
// replace is the string we want to replace the match with
fn (mut self ReplaceInstructions) add_item(regex_find_str string, replace_with string) ! {
	mut item := regex_find_str
	if item.starts_with('^R') {
		item = item[2..] // remove ^r
		r := regex.regex_opt(item) or { panic('regex_opt failed') }
		self.instructions << ReplaceInstruction{
			regex_str:    item
			regex:        r
			replace_with: replace_with
		}
	} else if item.starts_with('^S') {
		item = item[2..] // remove ^S
		item2 := regex_rewrite(item)!
		r := regex.regex_opt(item2) or { panic('regex_opt failed') }
		self.instructions << ReplaceInstruction{
			regex_str:    item
			regex:        r
			replace_with: replace_with
		}
	} else {
		self.instructions << ReplaceInstruction{
			replace_with: replace_with
			find_str:     item
		}
	}
}

// each element of the list can have more search statements .
// a search statement can have 3 forms.
//  - regex start with ^R see https://github.com/vlang/v/blob/master/vlib/regex/README.md .
//  - case insensitive string find start with ^S (will internally convert to regex).
//  - just a string, this is a literal find (case sensitive) .
// input is ["^Rregex:replacewith",...] .
// input is ["^Rregex:^Rregex2:replacewith"] .
// input is ["findstr:findstr:replacewith"] .
// input is ["findstr:^Rregex2:replacewith"] .
pub fn (mut ri ReplaceInstructions) add(replacelist []string) ! {
	for i in replacelist {
		splitted := i.split(':')
		replace_with := splitted[splitted.len - 1]
		// last one not to be used
		if splitted.len < 2 {
			return error("Cannot add ${i} because needs to have 2 parts, wrong syntax, to regex instructions:\n\"${replacelist}\"")
		}
		for item in splitted[0..(splitted.len - 1)] {
			ri.add_item(item, replace_with)!
		}
	}
}

// a text input file where each line has one of the following
//  - regex start with ^R see https://github.com/vlang/v/blob/master/vlib/regex/README.md .
//  - case insensitive string find start with ^S (will internally convert to regex).
//  - just a string, this is a literal find (case sensitive) .
// example input
// '''
// ^Rregex:replacewith
// ^Rregex:^Rregex2:replacewith
// ^Sfindstr:replacewith
// findstr:findstr:replacewith
// findstr:^Rregex2:replacewith
// ^Sfindstr:^Sfindstr2::^Rregex2:replacewith
// ''''
pub fn (mut ri ReplaceInstructions) add_from_text(txt string) ! {
	mut replacelist := []string{}
	for line in txt.split_into_lines() {
		if line.trim_space() == '' {
			continue
		}
		if line.contains(':') {
			replacelist << line
		}
	}
	ri.add(replacelist)!
}

@[params]
pub struct ReplaceArgs {
pub mut:
	text   string
	dedent bool
}

// this is the actual function which will take text as input and return the replaced result
// does the matching line per line .
// will use dedent function, on text
pub fn (mut self ReplaceInstructions) replace(args ReplaceArgs) !string {
	mut gi := 0
	mut text2 := args.text
	if args.dedent {
		text2 = texttools.dedent(text2)
	}
	mut line2 := ''
	mut res := []string{}

	if text2.len == 0 {
		return ''
	}
	// check if there is \n at end of text, because of splitlines would be lost
	mut endline := false
	if text2.ends_with('\n') {
		endline = true
	}
	for line in text2.split_into_lines() {
		line2 = line

		// mut tl := tokenize(line)

		for mut i in self.instructions {
			if i.find_str == '' {
				all := i.regex.find_all(line)
				for gi < all.len {
					gi += 2
				}
				line2 = i.regex.replace(line2, i.replace_with)
			} else {
				// line2 = line2.replace(i.find_str, i.replace_with)
				// line2 = tl.replace(line2, i.find_str, i.replace_with) ?

				line2 = line2.replace(i.find_str, i.replace_with)
			}
		}
		res << line2
	}

	mut x := res.join('\n')
	if !endline {
		x = x.trim_right('\n')
	}
	return x
}

@[params]
pub struct ReplaceDirArgs {
pub mut:
	path       string
	extensions []string
	dryrun     bool
}

// if dryrun is true then will not replace but just show
pub fn (mut self ReplaceInstructions) replace_in_dir(args ReplaceDirArgs) !int {
	mut count := 0
	// create list of unique extensions all lowercase
	mut extensions := []string{}
	for ext in args.extensions {
		if ext !in extensions {
			mut ext2 := ext.to_lower()
			if ext2.starts_with('.') {
				ext2 = ext2[1..]
			}
			extensions << ext2
		}
	}

	mut done := []string{}
	count += self.replace_in_dir_recursive(args.path, extensions, args.dryrun, mut done)!
	return count
}

// returns how many files changed
fn (mut self ReplaceInstructions) replace_in_dir_recursive(path1 string, extensions []string, dryrun bool, mut done []string) !int {
	items := os.ls(path1) or {
		return error('cannot load folder for replace because cannot find ${path1}')
	}
	mut pathnew := ''
	mut count := 0

	for item in items {
		pathnew = os.join_path(path1, item)
		// CAN DO THIS LATER IF NEEDED
		// if pathnew in done{
		// 	continue
		// }
		// done << pathnew
		if os.is_dir(pathnew) {
			if item.starts_with('.') {
				continue
			}
			if item.starts_with('_') {
				continue
			}

			self.replace_in_dir_recursive(pathnew, extensions, dryrun, mut done)!
		} else {
			ext := os.file_ext(pathnew)[1..].to_lower()
			if extensions == [] || ext in extensions {
				// means we match a file

				txtold := os.read_file(pathnew)!
				txtnew := self.replace(text: txtold, dedent: false)!
				if txtnew.trim(' \n') == txtold.trim(' \n') {
					// panic("need to move this file to other lib can't use print_header")
					console.print_header(' nothing to do : ${pathnew}')
				} else {
					// panic("need to move this file to other lib can't use print_header")
					console.print_header(' replace done  : ${pathnew}')
					count++
					if !dryrun {
						// now write the file back
						os.write_file(pathnew, txtnew)!
					}
				}
			}
		}
	}
	return count
}

pub fn regex_instructions_new() ReplaceInstructions {
	return ReplaceInstructions{}
}
