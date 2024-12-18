module playcmds

import freeflowuniverse.crystallib.core.playbook

const dagu_script = "
!!dagu.configure
	instance: 'test'
	username: 'admin'
	password: 'testpassword'

!!dagu.new_dag
	name: 'test_dag'

!!dagu.add_step
	dag: 'test_dag'
	name: 'hello_world'
	command: 'echo hello world'

!!dagu.add_step
	dag: 'test_dag'
	name: 'last_step'
	command: 'echo last step'


"

fn test_play_dagu() ! {
	mut plbook := playbook.new(text: dagu_script)!
	play_dagu(mut plbook)!
	panic('s')
}
