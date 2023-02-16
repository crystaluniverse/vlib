module telegram

import os
import freeflowuniverse.crystallib.ui.uimodel {QuestionArgs}


// args:
// - description string
// - question string
// - warning: string (if it goes wrong, which message to use)
// - clear bool = true
// - regex: to check what result need to be part of
// - minlen: min nr of chars
//

struct Output {
	message string
	response_channel chan string
}

pub fn (mut ui UITelegram) ask_question (args QuestionArgs) !string {
	mut message := ''
	
	if args.description.len > 0 {
		message += '${make_safe(args.description)}\n'
	}
	if args.warning.len > 0 {
		message += '__${make_safe(args.warning)}__\n'
	}
	mut question := 'Please provide an answer:'
	if args.question != '' {
		question = args.question
	}
	message += '*bold \*${make_safe(question)}*\n'

	response_channel := chan string{}

	// TODO figure out how I am going to pass around user_ids
	ui.to_user <- Output{
		message: message
		response_channel: response_channel
	}

	select {
		choice := <- response_channel {
			if args.minlen > 0 && choice.len < args.minlen {
				return ui.ask_question(
					reset: args.reset
					description: args.description
					warning: 'Min length of answer is: ${args.minlen}'
					question: args.question
				)
			} else {
				return choice
			}
		}
		3600 * time.second {
			return error("Timeout!")
		}
	}

	return choice
}

fn make_safe(text string) string {
	mut new_text := ''
	for character in text {
		new_text += '\\${character.ascii_str()}'
	}
	return new_text
}