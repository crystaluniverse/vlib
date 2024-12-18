module project

import freeflowuniverse.crystallib.baobab.db
import freeflowuniverse.crystallib.baobab.smartid
import freeflowuniverse.crystallib.data.ourtime

@[root_object]
pub struct Issue {
	db.Base
pub mut:
	title            string
	type_            IssueType
	description      string
	priority         Priority
	deadline         ourtime.OurTime
	assignment       []smartid.GID @[root_object: 'Person, Team']
	effort_remaining int // remaining hours
	percent_done     f64
	state            State
	costcenters      []smartid.GID @[root_object: CostCenter]
}

pub enum IssueType {
	event
	bug
	question
	remark
	task
}

// pub enum IssueStatus {
// 	suggested
// 	approved
// 	started
// 	verify
// 	closed
// }

// pub enum IssueType {
// 	pr
// 	feature
// 	bug
// 	question
// 	deal
// 	lead
// }

// pub struct Issue {
// pub mut:
// 	id           int
// 	title        string
// 	state        IssueStatus
// 	members      []IssueMemberShip
// 	deadline     system.OurTime
// 	dependencies []int // dependencies to other projects
// 	description  string
// 	comments     []int
// }

// pub enum IssueMemberType {
// 	owner
// 	stakeholder
// 	member
// 	observer
// }

// pub struct IssueMemberShip {
// pub mut:
// 	person     string
// 	group      string
// 	membertype IssueMemberType
// 	expiration system.OurTime
// }
