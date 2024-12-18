module project

import freeflowuniverse.crystallib.baobab.db
import freeflowuniverse.crystallib.data.ourtime

@[root_object]
pub struct Milestone {
	db.Base
pub mut:
	name         string
	title        string
	description  string
	priority     Priority
	deadline     ourtime.OurTime
	percent_done f64
	state        State
	project_id   smartid.GID   @[root_object: Project]
	owners       []smartid.GID @[root_object: Person]
	epics        []smartid.GID @[root_object: Epic]
}
