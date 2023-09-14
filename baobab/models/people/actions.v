module people

import freeflowuniverse.crystallib.baobab.actions { Actions }
import freeflowuniverse.crystallib.texttools
import freeflowuniverse.crystallib.params

fn (mut m MemDB) actions(actions_ Actions) ! {
	mut actions2 := actions_.filtersort(actor: 'people')!
	for action in actions2 {
		if action.name == 'person_define' {
			panic('implement person_define')
		}
	}
}
