module actionparser


pub struct ActionsParser {
pub mut:
	actions []Action
}

pub struct Action {
pub:
	name string
pub mut:
	params []Param
}

struct Param {
pub:
	name  string
	value string
}

