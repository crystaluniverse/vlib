module testactor

pub fn (mut actor Testactor) new_base_object(base_object BaseObject) !u32 {
	return actor.backend.new[BaseObject](base_object)!
}

pub fn (mut actor Testactor) get_base_object(id u32) !BaseObject {
	return actor.backend.get[BaseObject](id)!
}

pub fn (mut actor Testactor) set_base_object(base_object BaseObject) ! {
	actor.backend.set[BaseObject](base_object)!
}

pub fn (mut actor Testactor) delete_base_object(id u32) ! {
	actor.backend.delete[BaseObject](id)!
}

pub fn (mut actor Testactor) list_base_object() ![]BaseObject {
	return actor.backend.list[BaseObject]()!
}

pub struct BaseObjectFilter {
	text string
}

pub fn (mut actor Testactor) filter_base_object(filter BaseObjectFilter) ![]BaseObject {
	return actor.backend.filter[BaseObject, BaseObjectFilter](filter)!
}