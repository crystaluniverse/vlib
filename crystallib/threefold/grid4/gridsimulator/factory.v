module gridsimulator

import freeflowuniverse.crystallib.biz.spreadsheet
// import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.threefold.grid4.cloudslices

__global (
	grid_simulators shared map[string]&Simulator
)

pub struct Simulator {
pub mut:
	name   string
	sheet  &spreadsheet.Sheet
	params SimulatorArgs
	nodes  map[string]&cloudslices.Node
}

@[params]
pub struct SimulatorArgs {
pub mut:
	name      string = 'default' // name of simulation
	path      string
	git_url   string
	git_reset bool
	git_pull  bool
}

pub fn new(args_ SimulatorArgs) !Simulator {
	mut args := args_

	if args.name == '' {
		return error('simulation needs to have a name')
	}
	args.name = texttools.name_fix(args.name)
	// if args.mdbook_name == '' {
	// 	args.mdbook_name = args.name
	// }

	// mut cs := currency.new()
	mut sh := spreadsheet.sheet_new(name: 'tfgridsim_${args.name}')!
	mut sim := Simulator{
		name: args.name
		sheet: sh
		params: args
		// currencies: cs
	}

	if args.git_url.len > 0 {
		mut gs := gittools.new()!
		mut repo := gs.get_repo(
			url: args.git_url
			pull: args.git_pull
			reset: args.git_reset
			reload: false
		)!

		args.path = repo.get_path()!
	}

	simulator_set(sim)
	sim.load()!

	return sim
}

// get sheet from global
pub fn simulator_get(name string) !&Simulator {
	rlock grid_simulators {
		if name in grid_simulators {
			return grid_simulators[name]
		}
	}
	return error("cann't find tfgrid gridsimulator:'${name}' in global grid_simulators")
}

// remember sheet in global
pub fn simulator_set(sim Simulator) {
	lock grid_simulators {
		grid_simulators[sim.name] = &sim
	}
	spreadsheet.sheet_set(sim.sheet)
}

// load the mdbook content from path or git
pub fn (mut self Simulator) load() ! {
	console.print_header('GRID SIMULATOR LOAD ${self.params.name}')

	mut plbook := playbook.new(path: self.params.path)!

	self.play(mut plbook)!
}
