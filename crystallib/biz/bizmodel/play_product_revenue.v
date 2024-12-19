module bizmodel

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.core.texttools

// - name, e.g. for a specific project
// - descr, description of the revenue line item
// - revenue_setup, revenue for 1 item '1000usd'
// - revenue_setup_delay
// - revenue_monthly, revenue per month for 1 item
// - revenue_monthly_delay, how many months before monthly revenue starts
// - maintenance_month_perc, how much percent of revenue_setup will come back over months
// - cogs_setup, cost of good for 1 item at setup
// - cogs_setup_delay, how many months before setup cogs starts, after sales
// - cogs_setup_perc: what is percentage of the cogs (can change over time) for setup e.g. 0:50%

// - cogs_monthly, cost of goods for the monthly per 1 item
// - cogs_monthly_delay, how many months before monthly cogs starts, after sales
// - cogs_monthly_perc: what is percentage of the cogs (can change over time) for monthly e.g. 0:5%,12:10%

// - nr_sold: how many do we sell per month (is in growth format e.g. 10:100,20:200)
// - nr_months_recurring: how many months is recurring, if 0 then no recurring
//
fn (mut m BizModel) revenue_action(action Action) ! {
	mut name := action.params.get_default('name', '')!
	mut descr := action.params.get_default('descr', '')!
	if descr.len == 0 {
		descr = action.params.get_default('description', '')!
	}
	if name.len == 0 {
		// make name ourselves
		name = texttools.name_fix(descr)
	}

	name = texttools.name_fix(name)
	if name.len == 0 {
		return error('name and description is empty for ${action}')
	}
	name2 := name.replace('_', ' ').replace('-', ' ')
	descr = descr.replace('_', ' ').replace('-', ' ')

	mut product := Product{
		name:        name
		title:       action.params.get_default('title', name)!
		description: descr
	}
	m.products[name] = &product

	mut nr_months_recurring := action.params.get_int_default('nr_months_recurring', 60)!

	if nr_months_recurring == 0 {
		nr_months_recurring = 1
	}

	product.nr_months_recurring = nr_months_recurring

	mut revenue := m.sheet.row_new(
		name:        '${name}_revenue'
		growth:      action.params.get_default('revenue', '0:0')!
		tags:        'rev name:${name}'
		descr:       'Revenue for ${name2}'
		extrapolate: false
	)!

	mut revenue_setup := m.sheet.row_new(
		name:          '${name}_revenue_setup'
		growth:        action.params.get_default('revenue_setup', '0:0')!
		tags:          'rev name:${name}'
		descr:         'Setup Sales price for ${name2}'
		aggregatetype: .avg
	)!

	mut revenue_setup_delay := action.params.get_int_default('revenue_setup_delay', 0)!

	mut revenue_monthly := m.sheet.row_new(
		name:          '${name}_revenue_monthly'
		growth:        action.params.get_default('revenue_monthly', '0:0')!
		tags:          'rev name:${name}'
		descr:         'Monthly Sales price for ${name2}'
		aggregatetype: .avg
	)!

	mut revenue_monthly_delay := action.params.get_int_default('revenue_monthly_delay',
		1)!

	mut cogs := m.sheet.row_new(
		name:        '${name}_cogs'
		growth:      action.params.get_default('cogs', '0:0')!
		tags:        'rev name:${name}'
		descr:       'COGS for ${name2}'
		extrapolate: false
	)!

	if revenue.max() > 0 || cogs.max() > 0 {
		product.has_oneoffs = true
	}

    _ := m.sheet.row_new(
		name:          '${name}_cogs_perc'
		growth:        action.params.get_default('cogs_perc', '0')!
		tags:          'rev  name:${name}'
		descr:         'COGS as percent of revenue for ${name2}'
		aggregatetype: .avg
	)!

	mut cogs_setup := m.sheet.row_new(
		name:          '${name}_cogs_setup'
		growth:        action.params.get_default('cogs_setup', '0:0')!
		tags:          'rev name:${name}'
		descr:         'COGS for ${name2} Setup'
		aggregatetype: .avg
	)!

	mut cogs_setup_delay := action.params.get_int_default('cogs_setup_delay', 1)!

	mut cogs_setup_perc := m.sheet.row_new(
		name:          '${name}_cogs_setup_perc'
		growth:        action.params.get_default('cogs_setup_perc', '0')!
		tags:          'rev  name:${name}'
		descr:         'COGS as percent of revenue for ${name2} Setup'
		aggregatetype: .avg
	)!

	mut cogs_monthly := m.sheet.row_new(
		name:          '${name}_cogs_monthly'
		growth:        action.params.get_default('cogs_monthly', '0:0')!
		tags:          'rev name:${name}'
		descr:         'Cost of Goods (COGS) for ${name2} Monthly'
		aggregatetype: .avg
	)!

	mut cogs_monthly_delay := action.params.get_int_default('cogs_monthly_delay', 1)!

	mut cogs_monthly_perc := m.sheet.row_new(
		name:          '${name}_cogs_monthly_perc'
		growth:        action.params.get_default('cogs_monthly_perc', '0')!
		tags:          'rev  name:${name}'
		descr:         'COGS as percent of revenue for ${name2} Monthly'
		aggregatetype: .avg
	)!

	// if true{
	// 	println(cogs_setup_perc)
	// 	println(cogs_monthly_perc)
	// 	panic("sdsd")
	// }

	mut nr_sold := m.sheet.row_new(
		name:          '${name}_nr_sold'
		growth:        action.params.get_default('nr_sold', '0')!
		tags:          'rev  name:${name}'
		descr:         'nr of items sold/month for ${name2}'
		aggregatetype: .avg
	)!

	if nr_sold.max() > 0 {
		product.has_items = true
	}

	// CALCULATE THE TOTAL (multiply with nr sold)

	mut revenue_setup_total := revenue_setup.action(
		name:        '${name}_revenue_setup_total'
		descr:       'Setup sales for ${name2} total'
		action:      .multiply
		rows:        [nr_sold]
		delaymonths: revenue_setup_delay
	)!

	mut revenue_monthly_total := revenue_monthly.action(
		name:        '${name}_revenue_monthly_total'
		descr:       'Monthly sales for ${name2} total'
		action:      .multiply
		rows:        [nr_sold]
		delaymonths: revenue_monthly_delay
	)!

	mut cogs_setup_total := cogs_setup.action(
		name:        '${name}_cogs_setup_total'
		descr:       'Setup COGS for ${name2} total'
		action:      .multiply
		rows:        [nr_sold]
		delaymonths: cogs_setup_delay
	)!

	mut cogs_monthly_total := cogs_monthly.action(
		name:        '${name}_cogs_monthly_total'
		descr:       'Monthly COGS for ${name2} total'
		action:      .multiply
		rows:        [nr_sold]
		delaymonths: cogs_monthly_delay
	)!

	// DEAL WITH RECURRING

	if nr_months_recurring > 0 {
		revenue_monthly_total = revenue_monthly_total.recurring(
			name:     '${name}_revenue_monthly_recurring'
			descr:    'Revenue monthly recurring for ${name2}'
			nrmonths: nr_months_recurring
		)!
		cogs_monthly_total = cogs_monthly_total.recurring(
			name:     '${name}_cogs_monthly_recurring'
			descr:    'COGS recurring for ${name2}'
			nrmonths: nr_months_recurring
		)!

        _ := nr_sold.recurring(
			name:          '${name}_nr_sold_recurring'
			descr:         'Nr products active because of recurring for ${name2}'
			nrmonths:      nr_months_recurring
			aggregatetype: .max
		)!
		// if true{
		// 	println(nr_sold_recurring)
		// 	panic('sd')
		// }					
	}

	// cogs as percentage of revenue
	mut cogs_setup_from_perc := cogs_setup_perc.action(
		action: .multiply
		rows:   [revenue_setup_total]
		name:   '${name}_cogs_setup_from_perc'
	)!
	mut cogs_monthly_from_perc := cogs_monthly_perc.action(
		action: .multiply
		rows:   [revenue_monthly_total]
		name:   '${name}_cogs_monthly_from_perc'
	)!

	// if true{
	// 	println(revenue_setup_total)
	// 	println(cogs_setup_perc)
	// 	println(cogs_setup_from_perc)
	// 	println("montlhy")
	// 	println(revenue_monthly_total)
	// 	println(cogs_monthly_perc)
	// 	println(cogs_monthly_from_perc)
	// 	panic("sdsd")
	// }

	// mut cogs_from_perc:=cogs_perc.action(action:.multiply,rows:[revenue],name:"cogs_from_perc")!

	// DEAL WITH MAINTENANCE

	// make sum of all past revenue (all one off revenue, needed to calculate maintenance)
	mut temp_past := revenue.recurring(
		nrmonths: nr_months_recurring
		name:     'temp_past'
		// delaymonths:4
	)!

	mut maintenance_month_perc := action.params.get_percentage_default('maintenance_month_perc',
		'0%')!

	mut maintenance_month := m.sheet.row_new(
		name:   '${name}_maintenance_month'
		growth: '0:${maintenance_month_perc:.2f}'
		tags:   'rev name:${name}'
		descr:  'maintenance fee for ${name2}'
	)!

	maintenance_month.action(action: .multiply, rows: [temp_past])!

	// temp_past.delete()

	// TOTALS

	mut revenue_total := m.sheet.row_new(
		name:   '${name}_revenue_total'
		growth: '0:0'
		tags:   'rev revtotal name:${name}'
		descr:  'Revenue total for ${name2}.'
	)!

	mut cogs_total := m.sheet.row_new(
		name:   '${name}_cogs_total'
		growth: '0:0'
		tags:   'rev cogstotal name:${name}'
		descr:  'COGS total for ${name2}.'
	)!

	if revenue_total.max() > 0.0 || cogs_total.max() > 0.0 {
		product.has_revenue
	}

	revenue_total = revenue_total.action(
		action: .add
		rows:   [revenue, revenue_monthly_total, revenue_setup_total, maintenance_month]
	)!

	if revenue_total.max() > 0 {
		product.has_revenue = true
	}

	cogs_total = cogs_total.action(
		action: .add
		rows:   [cogs, cogs_monthly_total, cogs_setup_total, cogs_setup_from_perc,
			cogs_monthly_from_perc]
	)!

	// if true{
	// 	//println(m.sheet)
	// 	println(revenue_total)
	// 	println(cogs_total)
	// 	println(cogs)
	// 	println(cogs_monthly_total)
	// 	println(cogs_setup_total)
	// 	println(cogs_setup_from_perc)
	// 	println(cogs_monthly_from_perc)
	// 	panic("sdsd")

	// }
}

// revenue_total calculates and aggregates the total revenue and cost of goods sold (COGS) for the business model
fn (mut sim BizModel) revenue_total() ! {
	// Create a new row in the sheet to represent the total revenue across all products
	sim.sheet.group2row(
		name:  'revenue_total'
		tags:  ''
		descr: 'total revenue.'
	)!

	// Create a new row in the sheet to represent the total COGS across all products
	sim.sheet.group2row(
		name:  'cogs_total'
		tags:  ''
		descr: 'total cogs.'
	)!

	// Note: The following commented-out code block seems to be for debugging or future implementation
	// It demonstrates how to create a smaller version of the sheet with specific filters
	// if true{
	// 	// name          string
	// 	// namefilter    []string // only include the exact names as specified for the rows
	// 	// includefilter []string // matches for the tags
	// 	// excludefilter []string // matches for the tags
	// 	// period_months int = 12
	// 	mut r:=sim.sheet.tosmaller(name:"tmp",includefilter:["cogstotal"],period_months:12)!
	// 	println(r)
	// 	panic("sdsd")
	// }	
}
