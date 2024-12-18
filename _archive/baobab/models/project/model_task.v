module project

import freeflowuniverse.crystallib.baobab.db
import freeflowuniverse.crystallib.data.ourtime

@[root_object]
pub struct Task {
	db.Base
pub mut:
	story            smartid.GID @[root_object: Story]
	title            string
	description      string
	priority         Priority
	assignment       []smartid.GID @[root_object: 'Person, Team']
	deadline         ourtime.OurTime
	effort_remaining int // hours remaining
	percent_done     f64
	state            State
	costcenters      []smartid.GID @[root_object: CostCenter]
}
