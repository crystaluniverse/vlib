module jobmanager

import freeflowuniverse.crystallib.core.texttools { name_fix }
import freeflowuniverse.crystallib.data.encoder

pub struct Executor {
pub mut:
	id          u32    @[required]
	name        string @[required]
	description string
	state       ExecutorState @[required]
	actors      map[string]&Actor = map[string]&Actor{}
}

fn (mut e Executor) cleanup() {
	for _, mut actor in e.actors {
		actor.actions.clear()
	}
	e.actors.clear()
}

pub enum ExecutorState {
	init
	running
	error
	halted
}

pub fn (mut e Executor) add_actor(actor &Actor) ! {
	name_fixed := name_fix(actor.name)
	if name_fixed in e.actors {
		return error('Actor with name ${name_fixed} already exists')
	}
	e.actors[name_fixed] = actor
}

pub fn (e Executor) get_actor(name string) !&Actor {
	name_fixed := name_fix(name)
	if name_fixed !in e.actors {
		return error('Actor with name ${name_fixed} not found')
	}
	return e.actors[name_fixed] or { return error('Actor not found') }
}

@[heap]
pub struct Actor {
pub mut:
	name        string @[required]
	executor    string @[required] // References Executor.name
	description string
mut:
	actions map[string]&Action = map[string]&Action{}
}

fn (mut a Actor) cleanup() {
	a.actions.clear()
}

pub fn (mut a Actor) add_action(action &Action) ! {
	name_fixed := name_fix(action.name)
	if name_fixed in a.actions {
		return error('Action with name ${name_fixed} already exists')
	}
	if action.actor != a.name {
		return error('Action ${action.name} references different actor: ${action.actor}')
	}
	a.actions[name_fixed] = action
}

pub fn (a Actor) get_action(name string) !&Action {
	name_fixed := name_fix(name)
	if name_fixed !in a.actions {
		return error('Action with name ${name_fixed} not found')
	}
	return a.actions[name_fixed] or { return error('Action not found') }
}

@[heap]
pub struct Action {
pub mut:
	id          u32    @[required]
	name        string @[required]
	actor       string @[required]
	description string
	nrok        int
	nrfailed    int
	code        string
}

// encode encodes the Action struct to binary format
pub fn (a Action) encode() ![]u8 {
	mut e := encoder.new()

	// Add version byte (v1)
	e.add_u8(1)

	// Encode all fields
	e.add_u32(a.id)
	e.add_string(a.name)
	e.add_string(a.actor)
	e.add_string(a.description)
	e.add_int(a.nrok)
	e.add_int(a.nrfailed)
	e.add_string(a.code)

	return e.data
}

// decode decodes binary data into an Action struct
pub fn (mut a Action) decode(data []u8) ! {
	if data.len == 0 {
		return error('empty data')
	}

	mut d := encoder.decoder_new(data)

	// Read and verify version
	version := d.get_u8()
	if version != 1 {
		return error('unsupported version ${version}')
	}

	// Decode all fields
	a.id = d.get_u32()
	a.name = d.get_string()
	a.actor = d.get_string()
	a.description = d.get_string()
	a.nrok = d.get_int()
	a.nrfailed = d.get_int()
	a.code = d.get_string()
}

// encode encodes the Actor struct to binary format
pub fn (a Actor) encode() ![]u8 {
	mut e := encoder.new()

	// Add version byte (v1)
	e.add_u8(1)

	// Encode basic fields
	e.add_string(a.name)
	e.add_string(a.executor)
	e.add_string(a.description)

	// Encode actions map
	e.add_u16(u16(a.actions.len))
	for key, action in a.actions {
		e.add_string(key)
		encoded_action := action.encode()!
		e.add_u16(u16(encoded_action.len))
		e.data << encoded_action
	}

	return e.data
}

// decode decodes binary data into an Actor struct
pub fn (mut a Actor) decode(data []u8) ! {
	if data.len == 0 {
		return error('empty data')
	}

	mut d := encoder.decoder_new(data)

	// Read and verify version
	version := d.get_u8()
	if version != 1 {
		return error('unsupported version ${version}')
	}

	// Decode basic fields
	a.name = d.get_string()
	a.executor = d.get_string()
	a.description = d.get_string()

	// Decode actions map
	actions_len := d.get_u16()
	for _ in 0 .. actions_len {
		key := d.get_string()
		action_data_len := d.get_u16()
		mut action_data := []u8{}
		for _ in 0 .. action_data_len {
			action_data << d.get_u8()
		}

		mut action := &Action{
			id:    0
			name:  ''
			actor: ''
		}
		action.decode(action_data)!
		a.actions[key] = action
	}
}

// encode encodes the Executor struct to binary format
pub fn (e Executor) encode() ![]u8 {
	mut enc := encoder.new()

	// Add version byte (v1)
	enc.add_u8(1)

	// Encode basic fields
	enc.add_u32(e.id)
	enc.add_string(e.name)
	enc.add_string(e.description)
	unsafe { enc.add_u8(u8(e.state)) }

	// Encode actors map
	enc.add_u16(u16(e.actors.len))
	for key, actor in e.actors {
		enc.add_string(key)
		encoded_actor := actor.encode()!
		enc.add_u16(u16(encoded_actor.len))
		enc.data << encoded_actor
	}

	return enc.data
}

// decode decodes binary data into an Executor struct
pub fn (mut e Executor) decode(data []u8) ! {
	if data.len == 0 {
		return error('empty data')
	}

	mut d := encoder.decoder_new(data)

	// Read and verify version
	version := d.get_u8()
	if version != 1 {
		return error('unsupported version ${version}')
	}

	// Decode basic fields
	e.id = d.get_u32()
	e.name = d.get_string()
	e.description = d.get_string()
	unsafe {
		e.state = ExecutorState(d.get_u8())
	}
	// Decode actors map
	actors_len := d.get_u16()
	for _ in 0 .. actors_len {
		key := d.get_string()
		actor_data_len := d.get_u16()
		mut actor_data := []u8{}
		for _ in 0 .. actor_data_len {
			actor_data << d.get_u8()
		}

		mut actor := &Actor{
			name:     ''
			executor: ''
		}
		actor.decode(actor_data)!
		e.actors[key] = actor
	}
}
