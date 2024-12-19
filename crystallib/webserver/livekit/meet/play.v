module meet

import freeflowuniverse.crystallib.core.playbook

pub fn play(mut plbook playbook.PlayBook) !&App {
	
	livekit_actions := plbook.find(filter: 'livekit.')!
	if livekit_actions.len == 0 {
		return error('no livekit actions found')
	}

	for action in livekit_actions {
		mut p := action.params

		match action.name {
			'livekit.configure' {
				config := action.params.decode[AppConfig]()!
				return new(config)
			}
			else {
				println('Unknown action: ${action.name}')
			}
		}
	}
	return error('no configuration action found for livekit')
}