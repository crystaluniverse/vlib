module project

import freeflowuniverse.crystallib.baobab.db
import freeflowuniverse.crystallib.baobab.smartid
import freeflowuniverse.crystallib.data.ourtime

// track effort done on issue, story, requirement or task (can be multiple at once)
@[root_object]
pub struct Track {
	db.Base
pub mut:
	issues       []smartid.GID @[root_object: Issue]
	stories      []smartid.GID @[root_object: Story]
	requirements []smartid.GID @[root_object: Requirement]
	tasks        []smartid.GID @[root_object: Task]
	time         ourtime.OurTime
	description  string
}
