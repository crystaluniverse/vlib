module jobmanager

import freeflowuniverse.crystallib.core.texttools { name_fix }

// Params for finding executors
pub struct ExecutorFindParams {
pub mut:
	id         ?u32
	name       ?string
	state      ?ExecutorState
	actor_name ?string // Find executors that have an actor with this name
}

// Manager for Executor objects
pub struct ExecutorManager {
mut:
	executors map[u32]Executor
	last_id   u32
}

// Create a new executor manager
pub fn new_executor_manager() ExecutorManager {
	return ExecutorManager{
		executors: map[u32]Executor{}
		last_id:   0
	}
}

// Set (create/update) an executor
pub fn (mut m ExecutorManager) set(mut executor Executor) !Executor {
	if executor.id == 0 {
		// New executor
		m.last_id++
		executor.id = m.last_id
		if executor.state == ExecutorState.init {
			executor.state = .init
		}
	}
	m.executors[executor.id] = executor
	return executor
}

// Get an executor by ID
pub fn (m ExecutorManager) get(id u32) !Executor {
	if id in m.executors {
		return m.executors[id] or { return error('Failed to get executor') }
	}
	return error('Executor with ID ${id} not found')
}

// Get an executor by name
pub fn (m ExecutorManager) get_by_name(name string) !Executor {
	name_fixed := name_fix(name)
	for _, executor in m.executors {
		if name_fix(executor.name) == name_fixed {
			return executor
		}
	}
	return error('Executor with name ${name} not found')
}

// Delete an executor by ID
pub fn (mut m ExecutorManager) delete(id u32) ! {
	if id in m.executors {
		m.executors.delete(id)
		return
	}
	return error('Executor with ID ${id} not found')
}

// Delete all executors
pub fn (mut m ExecutorManager) delete_all() {
	m.executors.clear()
	m.last_id = 0
}

// Find executors based on parameters
pub fn (m ExecutorManager) find(params ExecutorFindParams) []Executor {
	mut result := []Executor{}

	for _, executor in m.executors {
		if !matches_executor_params(executor, params) {
			continue
		}
		result << executor
	}

	return result
}

// Helper function to check if an executor matches the find parameters
fn matches_executor_params(executor Executor, params ExecutorFindParams) bool {
	if id := params.id {
		if id != executor.id {
			return false
		}
	}
	if name := params.name {
		if name_fix(executor.name) != name_fix(name) {
			return false
		}
	}
	if state := params.state {
		if state != executor.state {
			return false
		}
	}
	if actor_name := params.actor_name {
		actor_name_fixed := name_fix(actor_name)
		if actor_name_fixed !in executor.actors {
			return false
		}
	}
	return true
}

// Add an actor to an executor
pub fn (mut m ExecutorManager) add_actor(executor_id u32, mut actor Actor) ! {
	if executor_id !in m.executors {
		return error('Executor with ID ${executor_id} not found')
	}
	mut executor := m.executors[executor_id] or { return error('Failed to get executor') }
	executor.add_actor(actor)!
	m.executors[executor_id] = executor
}

// Get an actor from an executor
pub fn (m ExecutorManager) get_actor(executor_id u32, actor_name string) !&Actor {
	if executor_id !in m.executors {
		return error('Executor with ID ${executor_id} not found')
	}
	executor := m.executors[executor_id] or { return error('Failed to get executor') }
	return executor.get_actor(actor_name)
}

// Add an action to an actor in an executor
pub fn (mut m ExecutorManager) add_action(executor_id u32, actor_name string, mut action Action) ! {
	if executor_id !in m.executors {
		return error('Executor with ID ${executor_id} not found')
	}
	mut executor := m.executors[executor_id] or { return error('Failed to get executor') }
	mut actor := executor.get_actor(actor_name)!
	actor.add_action(action)!
	executor.actors[name_fix(actor_name)] = actor
	m.executors[executor_id] = executor
}

// Get an action from an actor in an executor
pub fn (m ExecutorManager) get_action(executor_id u32, actor_name string, action_name string) !&Action {
	if executor_id !in m.executors {
		return error('Executor with ID ${executor_id} not found')
	}
	executor := m.executors[executor_id] or { return error('Failed to get executor') }
	actor := executor.get_actor(actor_name)!
	return actor.get_action(action_name)
}
