module main

import freeflowuniverse.crystallib.core.codemodel
import os

const circle_model = '${os.dir(@FILE)}/testdata/test_model/model.v'
const test_model = '${os.dir(@FILE)}/testdata/test_model/organization_model.v' // actor_target   = '${os.dir(os.dir(@FILE))}/actor2.v'

// methods_target = '${os.dir(os.dir(@FILE))}/methods2.v'

fn test_generate_definers() {
	generate_definers(
		circle_model: circle_model
		model_path:   test_model
	)!
	panic('s')
	// panic(definers.map(it.vgen()))
}
