module bizmodel

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.core.texttools

fn (mut m BizModel) cost_define_action(action Action) ! {
	mut name := action.params.get_default('name', '')!
	mut descr := action.params.get_default('descr', '')!
	if descr.len == 0 {
		descr = action.params.get('description')!
	}
	if name.len == 0 {
		// make name ourselves
		name = texttools.name_fix(descr) // TODO:limit len
	}
	mut cost := action.params.get_default('cost', '0.0')! // is extrapolated
	mut cost_one := action.params.get_default('cost_one', '')!

	department := action.params.get_default('department', 'unknown department')!
	cost_percent_revenue := action.params.get_percentage_default('cost_percent_revenue',
		'0%')!

	indexation := action.params.get_percentage_default('indexation', '0%')!

	if indexation > 0 {
		if cost.contains(':') {
			return error('cannot specify cost growth and indexation, should be no : inside cost param.')
		}
		// TODO: need to be able to go from e.g. month 6 and still do indexation
		mut cost_ := cost.int()
		cost2 := cost_ * (1 + indexation) * (1 + indexation) * (1 + indexation) * (1 + indexation) * (
			1 + indexation) * (1 + indexation) // 6 years, maybe need to look at months
		cost = '0:${cost},59:${cost2}'
		// console.print_debug(cost)
	}

	mut extrap := false
	if cost_one != '' {
		// if cost!=""{
		// 	return error("Cannot specify cost:'${cost}' and cost_one:'${cost_one}'.")
		// }
		extrap = false
		cost = cost_one
	} else {
		// if cost_one!=""{
		// 	return error("Cannot specify cost:'${cost}' and cost_one:'${cost_one}'.")
		// }
		extrap = true
	}

	mut cost_row := m.sheet.row_new(
		name:        'cost_${name}'
		growth:      cost
		tags:        'department:${department} ocost'
		descr:       'cost overhead for department ${department}'
		extrapolate: extrap
	)!
	cost_row.action(action: .reverse)!

	if cost_percent_revenue > 0 {
		mut revtotal := m.sheet.row_get('revenue_total')!
		mut cost_min := revtotal.action(
			action:        .multiply
			val:           cost_percent_revenue
			name:          'tmp3'
			aggregatetype: .avg
		)!
		cost_min.action(action: .forwardavg)! // avg out forward looking for 12 months	
		cost_min.action(action: .reverse)!
		cost_row.action(
			action: .min
			rows:   [cost_min]
		)!
		m.sheet.row_delete('tmp3')
	}
}

fn (mut sim BizModel) cost_total() ! {
	sim.sheet.group2row(
		name:    'hr_cost_total'
		include: ['hrcost']
		tags:    'pl'
		descr:   'total cost for hr'
	)!
}
