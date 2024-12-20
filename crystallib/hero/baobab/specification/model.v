module specification

import freeflowuniverse.crystallib.core.codemodel { Struct, Function }

pub struct ActorSpecification {
pub mut:
	name        string      @[omitempty]
	description string      @[omitempty]
	structure   Struct      @[omitempty]
	methods     []ActorMethod @[omitempty]
	objects     []BaseObject @[omitempty]
}

pub struct ActorMethod {
pub:
	name        string   @[omitempty]
	description string   @[omitempty]
	func        Function @[omitempty]
}

pub struct BaseObject {
pub:
	structure Struct      @[omitempty]
	methods   []Function  @[omitempty]
	children  []Struct    @[omitempty]
}