module paramsparser

import freeflowuniverse.crystallib.core.texttools

enum ParamStatus {
	start
	name       // found name of the var (could be an arg)
	value_wait // wait for value to start (can be quote or end of spaces and first meaningful char)
	value      // value started, so was no quote
	quote      // quote found means value in between ''
	value_end  // quote found means value in between ''
	comment
}

// convert text with e.g. color:red or color:'red' to arguments
// multiline is supported
// result is params object which allows you to query the info you need
// params is following:
//
// struct Params {
// 	params []Param
// 	args   []Arg
// }
// struct Arg {
// 	value string
// }
// struct Param {
// 	key   string
// 	value string
// }
// it has nice methods to query the params
pub fn parse(text string) !Params {
	mut text2 := texttools.dedent(text)
	// mut text2 := text
	// console.print_debug("****PARSER")
	// console.print_debug(text2)
	// console.print_debug("****PARSER END")
	text2 = text2.replace('"', "'")
	text2 = texttools.multiline_to_single(text2)!
	// console.print_debug("1")
	validchars := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_,./'

	mut ch := ''
	mut ch_prev := ''
	mut state := ParamStatus.start
	mut result := Params{}
	mut key := ''
	mut value := ''
	mut list := false
	mut comment := ''

	for i in 0 .. text2.len {
		ch = text2[i..i + 1]
		// println(" - '${ch_prev}${ch}' ${state}")

		if state == .value_end {
			if ch == ' ' {
				ch_prev = ch
				continue
			} else if ch == ',' {
				list = true
				// means we are in list, must wait for next value
				last_item := value.all_after_last(',')
				if requires_quotes(last_item) {
					value = '${value.all_before_last(',')},"${last_item}"'
				}
				state = .value_wait
			} else if ch == '\n' && list {
				list = false
			} else {
				state = .start
				result.set_with_comment(key, value, comment)
				key = ''
				value = ''
				comment = ''
			}
		}

		// check for comments end
		if state == .start {
			if ch == ' ' {
				ch_prev = ch
				continue
			}
			state = .name
		}
		if state == .name {
			if ch_prev == '/' && ch == '/' {
				// we are now comment
				state = .comment
				ch_prev = ch
				continue
			}

			if ch == ' ' && key == '' {
				ch_prev = ch
				continue
			}
			// waiting for :
			if ch == ':' {
				state = ParamStatus.value_wait
				ch_prev = ch
				continue
			} else if ch == ' ' {
				state = ParamStatus.start
				result.set_arg_with_comment(key, comment)
				key = ''
				comment = ''
				value = ''
				ch_prev = ch
				continue
			} else if !validchars.contains(ch) {
				print_backtrace()
				return error("text to params processor: parameters can only be A-Za-z0-9 and _., found illegal char: '${key}${ch}' in\n${text2}\n\n")
			} else {
				key += ch
				ch_prev = ch
				continue
			}
		}
		if state == .value_wait {
			if ch == "'" {
				state = .quote
				ch_prev = ch
				continue
			}
			// if ch == '[' {
			// 	state = .array
			// 	ch_prev = ch
			// 	value = ''
			// 	continue
			// }
			// means the value started, we can go to next state
			if ch != ' ' {
				state = .value
			}
		}

		if state == .value {
			if ch == ',' {
				// means in list and our value has ended
				value += ch
				list = true
				state = .value_wait
			}
		}

		if state == .value {
			if ch == ' ' {
				state = .value_end
				list = false
			} else {
				value += ch
			}
			ch_prev = ch
			continue
		}
		if state == .quote {
			if ch == "'" && ch_prev != '\\' {
				state = .value_end
			} else {
				value += ch
			}
			ch_prev = ch
			continue
		}

		// if state == .array {
		// 	if ch == ']' {
		// 		state = .start
		// 		result.set_with_comment(key, value, comment)
		// 		key = ''
		// 		value = ''
		// 		comment = ''
		// 	} else {
		// 		value += ch
		// 	}
		// 	ch_prev = ch
		// 	continue
		// }

		if state == .value || state == ParamStatus.start {
			if ch == '/' && ch_prev == '/' {
				// we are now comment
				state = .comment
			}
		}

		if state == ParamStatus.comment {
			if ch == '/' && ch_prev == '-' {
				state = .start
				ch_prev = ch
				continue
			}
			comment += ch
		}

		ch_prev = ch
	}

	// last value
	if state == ParamStatus.value || state == ParamStatus.quote || state == .value_end {
		if list {
			last_item := value.all_after_last(',')
			if requires_quotes(last_item) {
				value = '${value.all_before_last(',')},"${last_item}"'
			}
		}
		result.set_with_comment(key, value, comment)
	}

	if state == ParamStatus.name {
		if key != '' {
			result.set_arg_with_comment(key, comment)
		}
	}
	return result
}

// returns wether a provided value requires quotes
fn requires_quotes(value string) bool {
	if value.contains(' ') {
		return true
	}
	return false
}
