module bizmodel

import freeflowuniverse.crystallib.core.playbook { PlayBook }
import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.biz.spreadsheet

pub fn play(mut plbook PlayBook) ! {
	// first make sure we find a run action to know the name
	mut actions4 := plbook.actions_find(actor: 'bizmodel')!

	if actions4.len == 0 {
		return
	}

	knownactions := ['revenue_define', 'employee_define', 'department_define', 'funding_define',
		'costcenter_define', 'cost_define']

	for action in actions4 {
		// biz name needs to be specified in the the bizmodel hero actions
		bizname := action.params.get('bizname') or {
			return error("Can't find param: 'bizname' for ${action.actor}.${action.name} macro, is a requirement argument.")
		}
		mut sim := getset(bizname)!

		if action.name !in knownactions {
			return error("Can't find macro with name: ${action.name} for macro's for bizmodel.")
		}

		console.print_debug(action.name)
		match action.name {
			'revenue_define' {
				sim.revenue_action(action)!
			}
			'funding_define' {
				sim.funding_define_action(action)!
			}
			'costcenter_define' {
				sim.costcenter_define_action(action)!
			}
			else {}
		}
	}

	console.print_debug('TOTALS for bizmodel play')
	// now we have processed the macro's, we can calculate the totals
	rlock bizmodels {
		for _, mut sim in bizmodels {
			// sim.hr_total()!
			sim.cost_total()!
			sim.revenue_total()!
			sim.funding_total()!
		}
	}

	for action in actions4 {
		console.print_debug(action.name)
		// biz name needs to be specified in the the bizmodel hero actions
		bizname := action.params.get('bizname') or {
			return error("Can't find param: 'bizname' for bizmodel macro, is a requirement argument.")
		}

		mut sim := get(bizname)!

		if action.name !in knownactions {
			return error("Can't find macro with name: ${action.name} for macro's for bizmodel.")
		}

		match action.name {
			'cost_define' {
				sim.cost_define_action(action)!
			}
			'department_define' {
				sim.department_define_action(action)!
			}
			'employee_define' {
				sim.employee_define_action(action)!
			}
			else {}
		}
	}

	// mut sim:=get("test")!
	// //println(sim.sheet.rows.keys())
	// //println(spreadsheet.sheets_keys())
	// println(spreadsheet.sheet_get('bizmodel_test')!)
	// if true{panic("sss")}
}
