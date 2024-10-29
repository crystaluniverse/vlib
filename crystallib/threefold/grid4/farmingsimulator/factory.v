module farmingsimulator

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.biz.spreadsheet
import freeflowuniverse.crystallib.ui.console

__global (
	farmingsimulators shared map[string]&Simulator
)

@[params]
pub struct SimulatorArgs {
pub mut:
	name      string = 'default' // name of simulation
	path      string
	git_url   string
	git_reset bool
	git_pull  bool
}

// is called from the play
pub fn new(args_ SimulatorArgs) !Simulator {
	mut args := args_

	if args.name == '' {
		return error('simulation needs to have a name')
	}
	args.name = texttools.name_fix(args.name)

	console.print_header('farming simulator \'${args.name}\'')

	// if args.mdbook_name == '' {
	// 	args.mdbook_name = args.name
	// }

	// mut cs := currency.new()
	mut sh := spreadsheet.sheet_new(name: 'tffarmingsim_${args.name}')!
	mut sim := Simulator{
		name: args.name
		sheet: sh
		args: args
		// params: args
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

	if args.path.len > 0 {
		sim.load()!
	}

	simulator_set(sim)

	return sim
}

// get sheet from global
pub fn simulator_get(name string) !&Simulator {
	rlock farmingsimulators {
		if name in farmingsimulators {
			return farmingsimulators[name]
		}
	}
	return error("cann't find tfgrid gridsimulator:'${name}' in global farmingsimulators")
}

// remember sheet in global
pub fn simulator_set(sim Simulator) {
	lock farmingsimulators {
		farmingsimulators[sim.name] = &sim
	}
	spreadsheet.sheet_set(sim.sheet)
}

// load the mdbook content from path or git
fn (mut self Simulator) load() ! {
	console.print_header('farming simulator load from ${self.args.path}')

	mut plbook := playbook.new(path: self.args.path)!

	self.play(mut plbook)!
}
