module main

import freeflowuniverse.crystallib.ui

struct RoomOrderFlow {
	current_product string
	ui              ui.UserInterface
}

fn (mut f RoomOrderFlow) room_select() ! {
	i := f.ui.ask_dropdown_int(
		description: 'Which type of room do you want?'
		items:       ['penthouse', 'normal', 'single', 'appartment_room']
		warning:     'Please select your right type of room'
		reset:       true
	)
	// match	
	smoker := f.ui.ask_yesno(description: 'Are you a smoker?')
	if smoker {
		smoke := f.ui.ask_yesno(description: 'Do you want to smoke in your room?')
		if smoke == false {
			println('Please realize if we detect you have smoked in your room we will charge 100USD to deep clean the room.')
		}
	}
	if smoker == false {
		// TODO check there is a non smoking room.
		if false {
			println("We are very sorry, we didn't find a non smoking room, do you want another room or you are ok.")
		}
	}
}

fn do() ! {
	// open your flow and attach the required channel to it
	mut f := RoomOrderFlow{
		ui: ui.new(.console)
	}
	f.room_select()!

	// println(i)
}

fn main() {
	do() or { panic(err) }
}
