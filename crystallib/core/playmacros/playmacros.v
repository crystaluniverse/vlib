module playmacros

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.threefold.grid4.gridsimulator
import freeflowuniverse.crystallib.threefold.grid4.farmingsimulator
import freeflowuniverse.crystallib.biz.bizmodel
import freeflowuniverse.crystallib.biz.spreadsheet

pub fn play_actions(mut plbook playbook.PlayBook) ! {
	console.print_green('play actions (simulators)')
	farmingsimulator.play(mut plbook)!
	gridsimulator.play(mut plbook)!
	bizmodel.play(mut plbook)!
}

pub fn play_macro(action playbook.Action) !string {
	if action.actiontype != .macro {
		panic('should always be a macro')
	}
	console.print_green('macro: ${action.actor}:${action.name}')
	if action.actor == 'sheet' || action.actor == 'spreadsheet' {
		return spreadsheet.playmacro(action) or {
			return 'Macro error: ${action.actor}:${action.name}\n${err}'
		}
	} else if action.actor == 'tfgridsimulation_farming' {
		return farmingsimulator.playmacro(action) or {
			return 'Macro error: ${action.actor}:${action.name}\n${err}'
		}
	} else if action.actor == 'bizmodel' {
		return bizmodel.playmacro(action) or {
			return 'Macro error: ${action.actor}:${action.name}\n${err}'
		}
	} else {
		return "Macro error, Couldn't find macro: '${action.actor}:${action.name}'"
	}
	return ''
}
