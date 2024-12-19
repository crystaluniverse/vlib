module testactor

pub fn (mut actor Testactor) new_another_object(another_object AnotherObject) !u32 {
	return actor.backend.new[AnotherObject](another_object)!
}

pub fn (mut actor Testactor) get_another_object(id u32) !AnotherObject {
	return actor.backend.get[AnotherObject](id)!
}

pub fn (mut actor Testactor) set_another_object(another_object AnotherObject) ! {
	actor.backend.set[AnotherObject](another_object)!
}

pub fn (mut actor Testactor) delete_another_object(id u32) ! {
	actor.backend.delete[AnotherObject](id)!
}

pub fn (mut actor Testactor) list_another_object() ![]AnotherObject {
	return actor.backend.list[AnotherObject]()!
}

pub struct AnotherObjectFilter {
	text string
}

pub fn (mut actor Testactor) filter_another_object(filter AnotherObjectFilter) ![]AnotherObject {
	return actor.backend.filter[AnotherObject, AnotherObjectFilter](filter)!
}