module example

import organization
import freeflowuniverse.crystallib.baobab.actions as actionslib { ActionsArgs }
import freeflowuniverse.crystallib.data.paramsparser as paramslib { Params }

__global (
	actor_factory map[string]&ExampleActor
)

// PlayConfig. If actions are provided runs actions. Otherwise loads and runs actions in path.
pub struct Play {
	ActionsArgs
	actions []actionslib.Action
}

pub fn play(params Play) ! {
	actions := if params.actions.len > 0 {
		ap := actionslib.Actions{
			actions: params.actions
		}
		ap.filtersort(actor: '@actor_name')!
	} else {
		ap := actionslib.new(params.ActionsArgs)!
		ap.filtersort(actor: '@actor_name')!
	}

	for action in actions {
		actor_factory[action.circle].act(action)!
	}
}

struct ExampleActor {
mut:
	name     string
	epic_map shared map[string]&organization.Epic //
	// sprint_map map[string]&Sprint      //
	// story_map  map[string]&Story       //
}

pub fn (mut actor ExampleActor) act(action actionslib.Action) ! {
	match action.name {
		'get_epic' {
			actor.get_epic(action.params)!
		}
		'set_epic' {
			actor.set_epic(action.params)!
		}
		'delete_epic' {
			actor.delete_epic(action.params)!
		}
		'create_epic' {
			actor.create_epic(action.params)!
		}
		// 'get_sprint' {
		// 	actor.get_sprint(action.params)!
		// }
		// 'set_sprint' {
		// 	actor.set_sprint(action.params)!
		// }
		// 'delete_sprint' {
		// 	actor.delete_sprint(action.params)!
		// }
		// 'create_sprint' {
		// 	actor.create_sprint(action.params)!
		// }
		// 'get_story' {
		// 	actor.get_story(action.params)!
		// }
		// 'set_story' {
		// 	actor.set_story(action.params)!
		// }
		// 'delete_story' {
		// 	actor.delete_story(action.params)!
		// }
		// 'create_story' {
		// 	actor.create_story(action.params)!
		// }
		else {
			return error('action name ${action.name} not supported')
		}
	}
}

pub fn (actor ExampleActor) get_epic(params Params) !organization.Epic {
	id := params.get('id')!
	mut object := organization.Epic{}
	rlock actor.epic_map {
		object = *actor.epic_map[id] or { return error('key not found') }
	}
	return object
}

pub fn (shared actor ExampleActor) set_epic(params Params) ! {
	id := params.get('id')!
	if id !in actor.epic_map {
		return error('Root object with id does not exists.')
	}
	lock actor.epic_map {
		actor.epic_map[id] = &organization.Epic{
			...actor.epic_map[id]
		}
	}
}

pub fn (mut actor ExampleActor) delete_epic(params Params) ! {
	id := params.get('id')!
	lock actor.epic_map {
		actor.epic_map.delete(id)
	}
}

pub fn (shared actor ExampleActor) create_epic(params Params) ! {
	id := params.get('id')!
	if id in actor.epic_map {
		return error('Root object with id already exists.')
	}
	object := organization.Epic{
		// stories: params.get('stories')!
		// sprints: params.get('sprints')!
	}
	lock actor.epic_map {
		actor.epic_map[id] = &object
	}
}

// pub fn (shared actor ExampleActor) get_sprint(params Params) !Sprint {
// 	id := params.get('id')!
// 	mut object := Sprint{}
// 	rlock actor {
// 		object = actor.sprint_map[id]
// 	}
// }

// pub fn (shared actor ExampleActor) set_sprint(params Params) !Sprint {
// 	id := params.get('id')!
// 	if id !in actor.sprint_map {
// 		return error('Root object with id does not exists.')
// 	}
// 	lock actor {
// 		actor.sprint_map[id] = Sprint{
// 			...actor.sprint_map[id]
// 			title: params.get('title')!
// 			description: params.get('description')!
// 			stories: params.get('stories')!
// 		}
// 	}
// }

// pub fn (shared actor ExampleActor) delete_sprint(params Params) ! {
// 	id := params.get('id')!
// 	lock actor {
// 		actor.sprint_map.delete(id)
// 	}
// }

// pub fn (shared actor ExampleActor) create_sprint(params Params) ! {
// 	id := params.get('id')!
// 	if id in actor.sprint_map {
// 		return error('Root object with id already exists.')
// 	}
// 	object := Sprint{
// 		title: params.get('title')!
// 		description: params.get('description')!
// 		stories: params.get('stories')!
// 	}
// 	lock actor {
// 		actor.sprint_map[id] = object
// 	}
// }

// pub fn (shared actor ExampleActor) get_story(params Params) !Story {
// 	id := params.get('id')!
// 	mut object := Story{}
// 	rlock actor {
// 		object = actor.story_map[id]
// 	}
// }

// pub fn (shared actor ExampleActor) set_story(params Params) !Story {
// 	id := params.get('id')!
// 	if id !in actor.story_map {
// 		return error('Root object with id does not exists.')
// 	}
// 	lock actor {
// 		actor.story_map[id] = Story{
// 			...actor.story_map[id]
// 			title: params.get('title')!
// 			description: params.get('description')!
// 			tasks: [
// 				Task{
// 					asignee: params.get('tasks_asignee')!
// 					title: params.get('tasks_title')!
// 					description: params.get('tasks_description')!
// 					priority: {
// 					}
// 					tags: params.get('tasks_tags')!
// 				},
// 			]
// 		}
// 	}
// }

// pub fn (shared actor ExampleActor) delete_story(params Params) ! {
// 	id := params.get('id')!
// 	lock actor {
// 		actor.story_map.delete(id)
// 	}
// }

// pub fn (shared actor ExampleActor) create_story(params Params) ! {
// 	id := params.get('id')!
// 	if id in actor.story_map {
// 		return error('Root object with id already exists.')
// 	}
// 	object := Story{
// 		title: params.get('title')!
// 		description: params.get('description')!
// 		tasks: [
// 			Task{
// 				story_id: params.get('tasks_story_id')!
// 				asignee: params.get('tasks_asignee')!
// 				title: params.get('tasks_title')!
// 				description: params.get('tasks_description')!
// 				priority: {
// 				}
// 				tags: params.get('tasks_tags')!
// 			},
// 		]
// 	}
// 	lock actor {
// 		actor.story_map[id] = object
// 	}
// }
