module circles

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.data.paramsparser

__global (
	circle_actor shared CircleActor
)

struct CircleActor {
mut:
	circles map[string]&Circle
}

pub fn (shared actor CircleActor) act(action playbook.Action) ! {
	match action.name {
		'add_milestone' { actor.add_milestone(action.params)! }
		'add_member' { actor.add_member(action.params)! }
		'add_story' { actor.add_story(action.params)! }
		'set_status' { actor.set_status(action.params)! }
		else {}
	}
}

fn (shared actor CircleActor) add_milestone(params paramsparser.Params) ! {
	title := params.get('title')!
	description := params.get('description')!
	cid := params.get('cid')!

	lock actor {
		mut circle := actor.circles[cid]
		circle.add_milestone(
			title:       title
			description: description
		)
	}
}

fn (shared actor CircleActor) add_member(params paramsparser.Params) ! {
	member := params.get('member')!
	cid := params.get('cid')!

	lock actor {
		mut circle := actor.circles[cid]
		circle.add_member(
			member: member
		)
	}
}

fn (shared actor CircleActor) add_story(params paramsparser.Params) ! {
	title := params.get('title')!
	description := params.get('description')!
	cid := params.get('cid')!

	lock actor {
		mut circle := actor.circles[cid]
		circle.add_story(
			title:       title
			description: description
		)
	}
}

fn (shared actor CircleActor) set_status(params paramsparser.Params) ! {
	title := params.get('title')!
	description := params.get('description')!
	cid := params.get('cid')!

	rid := params.get('rid')!

	lock actor {
		mut circle := actor.circles[cid]
		circle.story.set_status(
			title:       title
			description: description
		)
	}
}
