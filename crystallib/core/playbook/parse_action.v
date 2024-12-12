module playbook

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.paramsparser

// TODO: maybe use this in playbook_add?
pub fn parse_single_action(action_text string) !Action {
	mut action := Action{}
	mut paramsdata := []string{}
	mut comments := []string{}
	mut state := State.start

	for line_ in action_text.split_into_lines() {
		line := line_.replace('\t', '    ')
		line_strip := line.trim_space()

		if line_strip.len == 0 {
			continue
		}

		if state == .action {
			if !line.starts_with('  ') || line_strip == '' || line_strip.starts_with('!') {
				state = .start
				action.params = paramsparser.new(paramsdata.join('\n'))!
				action.params.delete('id')
				return action
			} else {
				paramsdata << line
			}
		}

		if state == .comment_for_action_maybe {
			if line.starts_with('//') {
				comments << line_strip.trim_left('/ ')
			} else {
				state = .start
				action.comments = comments.join('\n')
				comments = []string{}
			}
		}

		if state == .start {
			if line_strip.starts_with('!') && !line_strip.starts_with('![') {
				state = .action
				action.comments = comments.join('\n')
				comments = []string{}
				paramsdata = []string{}
				mut actionname := line_strip
				if line_strip.contains(' ') {
					actionname = line_strip.all_before(' ').trim_space()
					paramsdata << line_strip.all_after_first(' ').trim_space()
				}
				if actionname.starts_with('!!!!!') {
					return error('There is no action starting with 5 x !')
				} else if actionname.starts_with('!!!!') {
					action.actiontype = .wal
				} else if actionname.starts_with('!!!') {
					action.actiontype = .macro
				} else if actionname.starts_with('!!') {
					action.actiontype = .sal
				} else if actionname.starts_with('!') {
					action.actiontype = .dal
				} else {
					return error('Unexpected action type')
				}
				actionname = actionname.trim_left('!')
				splitted := actionname.split('.')
				if splitted.len == 1 {
					action.actor = 'core'
					action.name = texttools.name_fix(splitted[0])
				} else if splitted.len == 2 {
					action.actor = texttools.name_fix(splitted[0])
					action.name = texttools.name_fix(splitted[1])
				} else {
					return error('Only actions with 1 or 2 parts are supported.\n${actionname}')
				}
				continue
			} else if line.starts_with('//') {
				state = .comment_for_action_maybe
				comments << line_strip.trim_left('/ ')
			}
		}
	}
	// Finalize if still in action state
	if state == .action && action.id == 0 {
		action.params = paramsparser.new(paramsdata.join('\n'))!
		action.params.delete('id')
	}
	return action
}