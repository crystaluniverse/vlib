module projectmanager

import freeflowuniverse.crystallib.baobab.actor

struct ProjectManager {
	actor.Actor
}

//
pub fn get(config actor.ActorConfig) !ProjectManager {
	return ProjectManager{
		Actor: actor.new(config)!
	}
}
