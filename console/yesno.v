module console

import os

pub struct YesNoArgs {
pub mut:
	description string
	question    string
	warning     string
	reset       bool = true
}

// yes is true, no is false
// args:
// - description string
// - question string
// - warning string
// - reset bool = true
//
pub fn ask_yesno(args YesNoArgs) bool {
	mut question := args.question
	if args.reset {
		clear() // clears the screen
	}
	if args.description.len > 0 {
		println(style(args.description, 'bold'))
	}
	if args.warning.len > 0 {
		println(color_fg(args.warning, 'red'))
		println('\n')
	}
	if question == '' {
		question = 'Yes or No, default is Yes (y/n)'
	}
	print('$question: ')
	choice := os.get_raw_line().trim(' \n').to_lower()
	if choice == '' {
		return true
	}
	if choice.starts_with('y') {
		return true
	}
	if choice.starts_with('1') {
		return true
	}
	if choice.starts_with('n') {
		return false
	}
	if choice.starts_with('0') {
		return false
	}
	return ask_yesno(
		description: args.description
		question: args.question
		warning: "Please choose 'y' or 'n', then enter."
		reset: true
	)
}
