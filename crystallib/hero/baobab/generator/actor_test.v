module generator

import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.core.pathlib
import os

fn test_generate_actor_struct() {
	generator := ActorGenerator{
		model_name: 'TestActor'
	}

	actor_struct := generator.generate_actor_struct()
	assert actor_struct.name == 'TestActor'
	assert actor_struct.embeds.len == 1
	assert actor_struct.embeds[0].name == 'actor.Actor'
}
