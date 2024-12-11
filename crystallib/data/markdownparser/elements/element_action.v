module elements

import freeflowuniverse.crystallib.core.playbook

@[heap]
pub struct Action {
	DocBase
pub mut:
	action           playbook.Action
	action_processed bool
}

// we don't allow an action to make child processes
pub fn (mut self Action) process() !int {
	if self.processed {
		return 0
	}
	// Should we process actions here?
	// p := playbook.new(text: self.content)!
	// if p.actions.len != 1 {
	// 	return error('a single action is expected, but found ${p.actions.len}')
	// }
	// self.action = p.actions[0]
	self.processed = true
	self.content = ''
	return 1
}

pub fn (self Action) markdown() !string {
	assert self.processed // needs to be processed before getting the markdown
	// if content set then we know the action was processed
	if self.action_processed || self.content != '' {
		return self.content
	}
	// not processed so return the original heroscript
	return self.action.heroscript()
}

pub fn (self Action) html() !string {
	return error('cannot return html, because there should be no actions left once we get to html')
}

pub fn (self Action) pug() !string {
	return error('cannot return html, because there should be no actions left once we get to html')
}
