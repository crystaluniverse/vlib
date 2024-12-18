module project

import freeflowuniverse.crystallib.baobab.db

pub struct Requirement {
	db.Base
pub mut:
	story       smartid.GID @[required; root_object: Story]
	title       string
	description string
	assignment  []smartid.GID @[root_object: 'Person, Team']
	priority    Priority
	state       RequirementState
}

pub enum RequirementState {
	unknown
	metonce
	metmulti
}
