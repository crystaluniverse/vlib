module farmingsimulator

import freeflowuniverse.crystallib.biz.spreadsheet

pub struct RegionalInternet {
pub mut:
	name      string
	batches   []NodesBatch
	simulator &Simulator @[str: skip]
	sheet     spreadsheet.Sheet
}

pub struct RegionalInternetNew {
pub mut:
	name string
}

pub fn (mut sim Simulator) regionalinternet_add(name string) !&RegionalInternet {
	mut sh := spreadsheet.sheet_new(name: 'regionalinternet_${name}', nrcol: sim.nrmonths) or {
		panic(err)
	}
	mut ri := RegionalInternet{
		name:      name
		simulator: &sim
		sheet:     sh
	}

	mut params := ri.simulator.params
	ri.sheet.row_new(name: 'nrnodes', aggregatetype: .max)!
	ri.sheet.row_new(name: 'powerusage')!
	ri.sheet.row_new(name: 'chi_total_tokens', growth: '1:0.0', aggregatetype: .max)!
	ri.sheet.row_new(name: 'rackspace', aggregatetype: .max)!

	// power and rackspace cost
	ri.sheet.row_new(name: 'cost_power', growth: params.env.power_cost)!
	ri.sheet.row_new(name: 'cost_power', growth: '1:0', tags: 'cost')!
	ri.sheet.row_new(name: 'rackspace_cost_unit', growth: params.env.rackspace_cost)!
	ri.sheet.row_new(name: 'rackspace_cost', growth: '1:0', tags: 'cost')!

	// how does the cost price increase per node
	ri.sheet.row_new(name: 'price_increase_nodecost', growth: params.farming.price_increase_nodecost)!
	// how does the support cost increase per node
	ri.sheet.row_new(name: 'support_cost_node', growth: params.farming.support_cost_node)!

	ri.sheet.row_new(name: 'cost_network', tags: 'cost')!
	ri.sheet.row_new(name: 'cost_hardware', tags: 'cost')!
	ri.sheet.row_new(name: 'cost_support', tags: 'cost')!

	ri.sheet.row_new(name: 'chi_price_usd', growth: params.tokens.chi_price_usd, aggregatetype: .max)!

	ri.sheet.row_new(name: 'chi_farmed_month', aggregatetype: .max)!

	// mut utilization_nodes := ri.sheet.row_new(name:'utilization_nodes',growth:ri.simulator.params.utilization_nodes,aggregatetype:.max)!

	sim.regional_internets[ri.name] = &ri

	return &ri
}

pub struct RegionalInternetNodesAddArgs {
pub mut:
	template NodeTemplate
	growth   string = '3:0,4:50,12:100,24:1000,60:5000'
}

// add nodes to a regional internet:
// args:
//   nodetemplate NodeTemplate
//   nodegrowth string = '3:0,4:50,12:5000,24:50000,60:1000000'	
pub fn (mut ri RegionalInternet) nodes_add(args RegionalInternetNodesAddArgs) ! {
	mut price_increase_nodecost_row := ri.sheet.row_get('price_increase_nodecost')!

	mut sh := spreadsheet.sheet_new(name: 'temp') or { panic(err) }
	mut nrnodes_add := sh.row_new(name: 'nrnodes_added', growth: args.growth)!
	// nrnodes_add.int()
	// mut nrnodes := nrnodes_add.aggregate('nrnodes')!
	// println(nrnodes_add)
	// println(nrnodes)
	mut month := 0
	for cell in nrnodes_add.cells {
		// mut sh_nb := calc.sheet_new(name: "nb",nrcol:ri.simulator.params.nrmonths) or { panic(err) }
		price_increase_nodecost := price_increase_nodecost_row.cell_get(month)!
		hw_cost := args.template.capacity.cost * price_increase_nodecost.val
		mut nb := NodesBatch{
			node_template:     &args.template
			hw_cost:           hw_cost
			nrnodes:           int(cell.val)
			start_month:       month
			nrmonths:          ri.simulator.nrmonths
			regional_internet: &ri
			// sheet: sh_nb
		}
		// nb.node_template.calc()//not needed done in each component step
		ri.batches << nb
		month += 1
	}
}

// calculate how a regional internet will expand in relation to the arguments given
pub fn (mut ri RegionalInternet) calc() ! {
	mut nrnodes := ri.sheet.row_get('nrnodes')!
	mut powerusage := ri.sheet.row_get('powerusage')!
	mut rackspace := ri.sheet.row_get('rackspace')!
	mut cost_power := ri.sheet.row_get('cost_power')!
	mut rackspace_cost := ri.sheet.row_get('rackspace_cost')!
	mut cost_hardware := ri.sheet.row_get('cost_hardware')!
	mut cost_support := ri.sheet.row_get('cost_support')!
	mut chi_farmed_month := ri.sheet.row_get('chi_farmed_month')!
	mut chi_total_tokens := ri.sheet.row_get('chi_total_tokens')!

	for x in 0 .. ri.simulator.nrmonths {
		for mut nb in ri.batches {
			res := nb.calc(x)!
			nrnodes.cells[x].add(res.nrnodes)
			powerusage.cells[x].add(res.power_kwh)
			rackspace.cells[x].add(res.rackspace)
			cost_power.cells[x].add(res.power_cost)
			rackspace_cost.cells[x].add(res.rackspace_cost)
			cost_hardware.cells[x].add(res.hw_cost)
			cost_support.cells[x].add(res.support_cost)
			chi_farmed_month.cells[x].add(res.tokens_farmed)
			if x > 0 {
				chi_total_tokens.cells[x].val = chi_farmed_month.cells[x].val +
					chi_total_tokens.cells[x - 1].val
			} else {
				chi_total_tokens.cells[x].val = chi_farmed_month.cells[x].val
			}
		}
	}
	// chi_farmed_month.divide('chi_farmed_month_node', nrnodes)!
	// mut chi_total_tokens := chi_farmed_month.aggregate("chi_total_tokens")!
}
