module bizmodel

import freeflowuniverse.crystallib.baobab.actions { Actions }
import freeflowuniverse.crystallib.texttools

// populate the params for hr
// !!hr.employee_define
//     descr:'Junior Engineer'
//     nrpeople:'1:5,60:30'
//	   cost:'4000USD'
//	   indexation:'5%'
//     department:'engineering'
//	   cost_percent_revenue e.g. 4%, will make sure the cost will be at least 4% of revenue

fn (mut m BizModel) overhead_actions(actions_ Actions) ! {
	mut actions2 := actions_.filtersort(actor: 'costs')!
	for action in actions2 {
		if action.name == 'define' {
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
				cost2 := cost_ * (1 + indexation) * (1 + indexation) * (1 + indexation) * (1 +
					indexation) * (1 + indexation) * (1 + indexation) // 6 years, maybe need to look at months
				cost = '0:${cost},59:${cost2}'
				// println(cost)
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
				name: 'cost_${name}'
				growth: cost
				tags: 'department:${department} ocost'
				descr: '"cost overhead for department ${department}'
				extrapolate: extrap
			)!
			cost_row.action(action: .reverse)!

			if cost_percent_revenue > 0 {
				mut revtotal := m.sheet.row_get('revenue_total')!
				mut cost_min := revtotal.action(
					action: .multiply
					val: cost_percent_revenue
					name: 'tmp3'
					aggregatetype: .avg
				)!
				cost_min.action(action: .forwardavg)! // avg out forward looking for 12 months	
				cost_min.action(action: .reverse)!
				cost_row.action(
					action: .min
					rows: [cost_min]
				)!
				m.sheet.row_delete('tmp3')
			}
		}
	}

	mut hr_cost_row := m.sheet.group2row(
		name: 'overhead_cost_total'
		include: ['ocost']
		tags: 'pl'
		descr: 'total cost for overhead.'
	)!
}
