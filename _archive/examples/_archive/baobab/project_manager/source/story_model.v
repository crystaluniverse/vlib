module source

pub struct Story {
pub mut:
	id   string
	name string @[required]
	tag  string @[index]
}
