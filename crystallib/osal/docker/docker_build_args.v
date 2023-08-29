module docker

import freeflowuniverse.crystallib.data.params { Params }

[params]
pub struct BuildArgs {
pub mut:
	reset  bool // resets the docker state, will build again
	strict bool // question: ?
	engine &DockerEngine
	args   Params
}