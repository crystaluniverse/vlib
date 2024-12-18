module investorsimulator

import freeflowuniverse.crystallib.core.playbook { PlayBook }
import freeflowuniverse.crystallib.biz.investortool

__global (
	simulators map[string]Simulator
)

@[params]
pub struct NewSimulatorArgs {
pub mut:
	name      string @[required]
	data_path string @[requried]
}

pub struct Simulator {
pub mut:
	name           string
	it             &investortool.InvestorTool
	user_views     map[string][]&investortool.User
	investor_views map[string][]&investortool.Investor
	// captable_views map[string]CapTable
}

pub fn new(args NewSimulatorArgs) !Simulator {
	mut plbook := playbook.new(path: args.data_path)!
	mut it := investortool.play(mut plbook)!

	return Simulator{
		name:           args.name
		it:             it
		user_views:     map[string][]&investortool.User{}
		investor_views: map[string][]&investortool.Investor{}
	}
}

pub fn play(mut plbook PlayBook) ! {
	for mut action in plbook.find(filter: 'investorsimulator.run')! {
		name := action.params.get_default('name', 'default')!
		data_path := action.params.get('data_path')!
		mut sim := new(name, data_path)!

		lock simulators {
			simulators[name] = sim
		}

		sim.play(mut plbook)!
	}
}
