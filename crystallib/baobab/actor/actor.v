module actor

import freeflowuniverse.crystallib.baobab.osis

pub struct Actor {
pub mut:
	osis osis.OSIS
}

pub struct ActorConfig {
	osis.OSISConfig
}

pub fn new(config ActorConfig) !Actor {
	return Actor{
		osis: osis.new(config.OSISConfig)!
	}
}
