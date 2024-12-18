module example

import freeflowuniverse.crystallib.baobab.actions as actionslib { Actions, ActionsArgs }
import freeflowuniverse.crystallib.data.paramsparser as paramslib { Params }

__global (
	actor_factory map[string]shared ExampleActor
)

// PlayConfig. If actions are provided runs actions. Otherwise loads and runs actions in path.
pub struct Play {
	ActionsArgs
	actions []Actions
}

pub fn play(params Play) ! {
	actor_actions := if params.actions.len > 0 {
		params.actions
	} else {
		actionslib.new(params.ActionsArgs)
	}

	for action in actions.filtersort(actor: '') {
		actor_factory[cid].act(action)!
	}
}

struct ExampleActor {
	epic_map   map[string]&Epic   //
	sprint_map map[string]&Sprint //
	story_map  map[string]&Story  //
}

pub fn (shared actor ExampleActor) act(action actions.Action) {
	'get_epic'
	{
		actor.get_epic(action.params)!
	}
	'set_epic'
	{
		actor.set_epic(action.params)!
	}
	'delete_epic'
	{
		actor.delete_epic(action.params)!
	}
	'create_epic'
	{
		actor.create_epic(action.params)!
	}
	'get_sprint'
	{
		actor.get_sprint(action.params)!
	}
	'set_sprint'
	{
		actor.set_sprint(action.params)!
	}
	'delete_sprint'
	{
		actor.delete_sprint(action.params)!
	}
	'create_sprint'
	{
		actor.create_sprint(action.params)!
	}
	'get_story'
	{
		actor.get_story(action.params)!
	}
	'set_story'
	{
		actor.set_story(action.params)!
	}
	'delete_story'
	{
		actor.delete_story(action.params)!
	}
	'create_story'
	{
		actor.create_story(action.params)!
	}
}

pub fn (shared actor ExampleActor) get_epic(params Params) !Epic {
	id := params.get('id')!
	mut object := Epic{}
	rlock actor {
		object = actor.epic_map[id]
	}
}

pub fn (shared actor ExampleActor) set_epic(params Params) !Epic {
	id := params.get('id')!
	if id !in actor.epic_map {
		return error('Root object with id does not exists.')
	}
	lock actor {
		actor.epic_map[id] = Epic{
			...actor.epic_map[id]
			stories: params.get('stories')!
			sprints: params.get('sprints')!
		}
	}
}

pub fn (shared actor ExampleActor) delete_epic(params Params) ! {
	id := params.get('id')!
	lock actor {
		actor.epic_map.delete(id)
	}
}

pub fn (shared actor ExampleActor) create_epic(params Params) ! {
	id := params.get('id')!
	if id in actor.epic_map {
		return error('Root object with id already exists.')
	}
	object := Epic{
		stories: params.get('stories')!
		sprints: params.get('sprints')!
	}
	lock actor {
		actor.epic_map[id] = object
	}
}

pub fn (shared actor ExampleActor) get_sprint(params Params) !Sprint {
	id := params.get('id')!
	mut object := Sprint{}
	rlock actor {
		object = actor.sprint_map[id]
	}
}

pub fn (shared actor ExampleActor) set_sprint(params Params) !Sprint {
	id := params.get('id')!
	if id !in actor.sprint_map {
		return error('Root object with id does not exists.')
	}
	lock actor {
		actor.sprint_map[id] = Sprint{
			...actor.sprint_map[id]
			title:       params.get('title')!
			description: params.get('description')!
			stories:     params.get('stories')!
		}
	}
}

pub fn (shared actor ExampleActor) delete_sprint(params Params) ! {
	id := params.get('id')!
	lock actor {
		actor.sprint_map.delete(id)
	}
}

pub fn (shared actor ExampleActor) create_sprint(params Params) ! {
	id := params.get('id')!
	if id in actor.sprint_map {
		return error('Root object with id already exists.')
	}
	object := Sprint{
		title:       params.get('title')!
		description: params.get('description')!
		stories:     params.get('stories')!
	}
	lock actor {
		actor.sprint_map[id] = object
	}
}

pub fn (shared actor ExampleActor) get_story(params Params) !Story {
	id := params.get('id')!
	mut object := Story{}
	rlock actor {
		object = actor.story_map[id]
	}
}

pub fn (shared actor ExampleActor) set_story(params Params) !Story {
	id := params.get('id')!
	if id !in actor.story_map {
		return error('Root object with id does not exists.')
	}
	lock actor {
		actor.story_map[id] = Story{
			...actor.story_map[id]
			title:       params.get('title')!
			description: params.get('description')!
			tasks:       [
				Task{
					asignee:     params.get('tasks_asignee')!
					title:       params.get('tasks_title')!
					description: params.get('tasks_description')!
					priority:    {
					}
					tags:        params.get('tasks_tags')!
				},
			]
		}
	}
}

pub fn (shared actor ExampleActor) delete_story(params Params) ! {
	id := params.get('id')!
	lock actor {
		actor.story_map.delete(id)
	}
}

pub fn (shared actor ExampleActor) create_story(params Params) ! {
	id := params.get('id')!
	if id in actor.story_map {
		return error('Root object with id already exists.')
	}
	object := Story{
		title:       params.get('title')!
		description: params.get('description')!
		tasks:       [
			Task{
				story_id:    params.get('tasks_story_id')!
				asignee:     params.get('tasks_asignee')!
				title:       params.get('tasks_title')!
				description: params.get('tasks_description')!
				priority:    {
				}
				tags:        params.get('tasks_tags')!
			},
		]
	}
	lock actor {
		actor.story_map[id] = object
	}
}
