module bizmodel

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.data.markdownparser.elements
import freeflowuniverse.crystallib.ui.console

pub fn playmacro(action playbook.Action) !string {
	p := action.params

	bizname := action.params.get('bizname') or {
		return error("Can't find param:'bizname' for action: ${action.name}, please specify as bizname: ...")
	}

	mut sim := get(bizname)!

	if action.name == 'employee_wiki' {
		return employee_wiki(p, sim)!
	} else if action.name == 'employees_wiki' {
		return employees_wiki(p, sim)!
	} else if action.name == 'department_wiki' {
		return department_wiki(p, sim)!
	} else if action.name == 'revenues_wiki' {
		return revenues_wiki(p, mut sim)!
	}

	return error("couldn't find macro '${action.name}' for bizmodel.")
}

fn employee_wiki(p paramsparser.Params, sim BizModel) !string {
	console.print_green('playmacro employee_wiki')
	mut id := p.get_default('id', '')!
	if id !in sim.employees {
		id = p.get_default('name', '')!
	}

	if id !in sim.employees {
		println(id)
		println(sim.employees)
		panic('sss')
		return error('employee with name \'${id}\' not found')
	}

	employee := sim.employees[id] or { panic('bug') }

	println(employee)

	// OUTPUTS:
	// &bizmodel.Employee{
	//     name: 'despiegk'
	//     description: 'CTO'
	//     department: 'engineering'
	//     cost: '1:12000EUR,60:21258.73200000001'
	//     cost_percent_revenue: 0.0
	//     nrpeople: '1'
	//     indexation: 0.1
	//     cost_center: 'default_costcenter'
	//     page: 'cto.md'
	// }	

	// if true{panic("s")}

    // theme := 'light'
    // theme := 'dark'  // Removed unused variable
    mut t := $tmpl('./templates/employee.md')
	return t
}

fn employees_wiki(p paramsparser.Params, sim BizModel) !string {
	mut deps := []Department{}
	for _, dep in sim.departments {
		deps << dep
	}
	deps.sort(a.order < b.order)

	mut employee_names := map[string]string{}
	for _, empl in sim.employees {
		employee_names[empl.name] = empl.name
		if empl.page.len > 0 {
			employee_names[empl.name] = '[${empl.name}](${empl.page})'
		}
	}
	mut t := $tmpl('./templates/departments.md')

	return t
}

fn department_wiki(p paramsparser.Params, sim BizModel) !string {
	return ''
}

fn revenues_wiki(p paramsparser.Params, mut sim BizModel) !string {
    // mut revs := map[string]string{}  // Removed unused variable

    // for name,_ in sim.products{
	// 	myrow:=sim.sheet.row_get('${name}_rev_total') or { panic("bug in revenues_wiki macro") }
	// 	println(myrow)
	// }

	// if true{
	// 	panic("s")
	// }

	panic('fix template below')
	// mut t:=$tmpl('./templates/revenue_overview.md')

	// title:'REVENUE FOR ${name1.to_lower().replace("_"," ")}'

	// return t
}
