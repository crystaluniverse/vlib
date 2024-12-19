module generator

import freeflowuniverse.crystallib.core.codemodel { Function, Module, Struct }
import os

pub struct ActorGenerator {
	model_name string
}

pub struct Actor {
pub mut:
	name        string
	description string
	structure   Struct
	mod         Module
	methods     []ActorMethod
	objects     []BaseObject
}

pub struct ActorMethod {
pub:
	name string
	func Function
}

pub struct BaseObject {
pub:
	structure Struct
	methods   []Function
	children  []Struct
}
