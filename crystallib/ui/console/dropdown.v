module console

// import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.ui.console { color_fg }
import freeflowuniverse.crystallib.ui.uimodel { DropDownArgs }
import os

fn (mut c UIConsole) ask_dropdown_internal(args DropDownArgs) !string {
	if silent_get() {
		panic("can't do ask_... when in silent mode")
	}
	if args.clear {
		clear() // clears the screen
	}
	if args.description.len > 0 {
		cprintln(style: .bold, text: args.description)
	}
	if args.warning.len > 0 {
		cprintln(foreground: .red, text: args.warning + '\n')
	}
	print_debug('\nChoices: ${args.choice_message}\n')
	mut items2 := args.items.clone()
	items2.sort()
	mut nr := 0
	for item in items2 {
		nr += 1
		print_header(' ${nr} : ${item}')
	}
	if args.all {
		print_header(' all : *')
	}
	if args.default.len > 0 {
		print_debug('\n - default : ${args.default.join(',')} (press enter to select default)')
	}
	print_debug('')
	print_debug(' - Make your choice:')
	choice := os.get_raw_line().trim(' \n')
	if choice.trim_space() == '*' {
		// means we return all
		return '999999'
	}
	if choice.trim_space() == '' && args.default.len > 0 {
		return '999998'
	}
	return choice
}

// return the dropdown as an int
// 	description string
// 	items       []string
// 	warning     string
// 	clear       bool = true
pub fn (mut c UIConsole) ask_dropdown_int(args_ DropDownArgs) !int {
	if silent_get() {
		panic("can't do ask_... when in silent mode")
	}
	mut args := args_
	args.items.sort()
	choice := c.ask_dropdown_internal(args)!

	nr := args.items.len

	if choice.contains(',') {
		return c.ask_dropdown_int(
			clear:       true
			description: args.description
			all:         args.all
			items:       args.items
			default:     args.default
			warning:     'Choice needs to be a number larger than 0 and smaller than ${nr + 1}, and only 1 return'
		)!
	}

	choice_int := choice.int()

	if choice_int == 999999 {
		return 1
	} else if choice_int == 999998 {
		default := args.default[0] or { return 1 }
		return args.items.index(default) + 1
	}

	if choice_int < 1 || choice_int > nr {
		return c.ask_dropdown_int(
			clear:       true
			description: args.description
			all:         args.all
			items:       args.items
			default:     args.default
			warning:     'Choice needs to be a number larger than 0 and smaller than ${nr + 1}'
		)!
	}
	return choice_int
}

// result can be multiple, aloso can select all
// 	description string
// 	items       []string
// 	warning     string
// 	clear       bool = true
pub fn (mut c UIConsole) ask_dropdown_multiple(args_ DropDownArgs) ![]string {
	if silent_get() {
		panic("can't do ask_... when in silent mode")
	}
	mut args := args_
	args.items.sort()
	res := c.ask_dropdown_internal(
		clear:          args.clear
		description:    args.description
		all:            args.all
		items:          args.items
		default:        args.default
		warning:        args.warning
		choice_message: '(multiple is possible)'
	)!
	if res == '999999' {
		return args.items
	} else if res == '999998' {
		return args.default
	}

	// check valid input
	mut bad := false
	nr := args.items.len
	for item in res.split(',') {
		if item.trim_space().len > 0 {
			choice_int := item.int()
			if choice_int < 1 || choice_int > nr {
				bad = true
			}
		}
	}

	if bad {
		return c.ask_dropdown_multiple(
			clear:       true
			description: args.description
			all:         args.all
			items:       args.items
			default:     args.default
			warning:     'Choice needs to be a number larger than 0 and smaller than ${nr + 1}'
		)!
	}

	mut res2 := []string{}
	for item in res.split(',') {
		if item.trim_space().len > 0 {
			i := item.int()
			res2 << args.items[i - 1] or { panic('bug') }
		}
	}
	return res2
}

// will return the string as given as response
// 	description string
// 	items       []string
// 	warning     string
// 	clear       bool = true
pub fn (mut c UIConsole) ask_dropdown(args DropDownArgs) !string {
	if silent_get() {
		panic("can't do ask_... when in silent mode")
	}
	res := c.ask_dropdown_int(
		clear:       args.clear
		description: args.description
		all:         args.all
		items:       args.items
		default:     args.default
		warning:     ''
	)!
	if res == 999998 {
		if args.default.len > 1 {
			return error('more than 1 default for single choice.\n${args}')
		}
		print(args)
		return args.default[0] or { panic('bug in default args for ask_dropdown_string.\n') }
	}
	return args.items[res - 1]
}
