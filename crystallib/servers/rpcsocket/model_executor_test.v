module rpcsocket

fn test_executor_creation() {
	mut executor := Executor{
		id: 1
		name: 'test_executor'
		state: .init
	}
	assert executor.id == 1
	assert executor.name == 'test_executor'
	assert executor.state == .init
	assert executor.actors.len == 0
}

fn test_executor_add_get_actor() ! {
	mut executor := Executor{
		id: 1
		name: 'test_executor'
		state: .init
	}

	mut actor := &Actor{
		name: 'test_actor'
		executor: 'test_executor'
		description: 'Test actor description'
	}

	executor.add_actor(actor)!
	retrieved_actor := executor.get_actor('test_actor')!

	assert retrieved_actor.name == 'test_actor'
	assert retrieved_actor.executor == 'test_executor'
	assert retrieved_actor.description == 'Test actor description'
}

fn test_executor_duplicate_actor() ! {
	mut executor := Executor{
		id: 1
		name: 'test_executor'
		state: .init
	}

	mut actor1 := &Actor{
		name: 'test_actor'
		executor: 'test_executor'
	}

	mut actor2 := &Actor{
		name: 'test_actor'
		executor: 'test_executor'
	}

	executor.add_actor(actor1)!
	if _ := executor.add_actor(actor2) {
		assert false, 'Should not allow duplicate actor names'
	}
}

fn test_actor_add_get_action() ! {
	mut actor := &Actor{
		name: 'test_actor'
		executor: 'test_executor'
	}

	mut action := &Action{
		id: 1
		name: 'test_action'
		actor: 'test_actor'
		description: 'Test action description'
	}

	actor.add_action(action)!
	retrieved_action := actor.get_action('test_action')!

	assert retrieved_action.id == 1
	assert retrieved_action.name == 'test_action'
	assert retrieved_action.actor == 'test_actor'
	assert retrieved_action.description == 'Test action description'
}

fn test_action_encode_decode() ! {
	original := Action{
		id: 1
		name: 'test_action'
		actor: 'test_actor'
		description: 'Test description'
		nrok: 5
		nrfailed: 2
		code: 'test code'
	}

	encoded := original.encode()!
	mut decoded := Action{
		id: 0
		name: ''
		actor: ''
	}
	decoded.decode(encoded)!

	assert decoded.id == original.id
	assert decoded.name == original.name
	assert decoded.actor == original.actor
	assert decoded.description == original.description
	assert decoded.nrok == original.nrok
	assert decoded.nrfailed == original.nrfailed
	assert decoded.code == original.code
}

fn test_actor_encode_decode() ! {
	mut original := Actor{
		name: 'test_actor'
		executor: 'test_executor'
		description: 'Test description'
	}

	mut action := &Action{
		id: 1
		name: 'test_action'
		actor: 'test_actor'
		description: 'Test action'
	}
	original.add_action(action)!

	encoded := original.encode()!
	mut decoded := Actor{
		name: ''
		executor: ''
	}
	decoded.decode(encoded)!

	assert decoded.name == original.name
	assert decoded.executor == original.executor
	assert decoded.description == original.description
	assert decoded.actions.len == original.actions.len

	decoded_action := decoded.get_action('test_action')!
	assert decoded_action.id == action.id
	assert decoded_action.name == action.name
	assert decoded_action.actor == action.actor
}

fn test_executor_encode_decode() ! {
	mut original := Executor{
		id: 1
		name: 'test_executor'
		description: 'Test description'
		state: .running
	}

	mut actor := &Actor{
		name: 'test_actor'
		executor: 'test_executor'
		description: 'Test actor'
	}

	mut action := &Action{
		id: 1
		name: 'test_action'
		actor: 'test_actor'
		description: 'Test action'
	}

	actor.add_action(action)!
	original.add_actor(actor)!

	encoded := original.encode()!
	mut decoded := Executor{
		id: 0
		name: ''
		state: .init
	}
	decoded.decode(encoded)!

	assert decoded.id == original.id
	assert decoded.name == original.name
	assert decoded.description == original.description
	assert decoded.state == original.state
	assert decoded.actors.len == original.actors.len

	decoded_actor := decoded.get_actor('test_actor')!
	assert decoded_actor.name == actor.name
	assert decoded_actor.executor == actor.executor

	decoded_action := decoded_actor.get_action('test_action')!
	assert decoded_action.id == action.id
	assert decoded_action.name == action.name
	assert decoded_action.actor == action.actor
}

fn test_invalid_actor_reference() ! {
	mut actor := &Actor{
		name: 'test_actor'
		executor: 'test_executor'
	}

	mut action := &Action{
		id: 1
		name: 'test_action'
		actor: 'different_actor' // Incorrect actor reference
	}

	if _ := actor.add_action(action) {
		assert false, 'Should not allow action with incorrect actor reference'
	}
}

fn test_get_nonexistent_actor() ! {
	mut executor := Executor{
		id: 1
		name: 'test_executor'
		state: .init
	}

	if _ := executor.get_actor('nonexistent') {
		assert false, 'Should not find nonexistent actor'
	}
}

fn test_get_nonexistent_action() ! {
	mut actor := &Actor{
		name: 'test_actor'
		executor: 'test_executor'
	}

	if _ := actor.get_action('nonexistent') {
		assert false, 'Should not find nonexistent action'
	}
}
