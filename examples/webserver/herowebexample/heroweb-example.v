module main

import freeflowuniverse.crystallib.web.heroweb
import os

fn main() {

	os.chdir('${os.home_dir()}/code/github/freeflowuniverse/crystallib/crystallib/webserver/heroweb') or {
		println('Error changing directory: ${err}')
		exit(1)
	}


	
	heroweb.example() or {
		println("Error: ${err}")
		exit(1)
	}


}