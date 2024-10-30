module gridsimulator

import freeflowuniverse.crystallib.core.playbook { PlayBook }
import freeflowuniverse.crystallib.threefold.grid4.cloudslices

pub fn play(mut plbook PlayBook) ! {
	// first make sure we find a run action to know the name
	mut my_actions := plbook.actions_find(actor: 'tfgrid_simulator')!

	if my_actions.len == 0 {
		return
	}

	mut name := ''

	for mut action in my_actions {
		if action.name == 'run' {
			name = action.params.get_default('name', 'default')! // when name not specified is 'default'

			mut sim := new(
				name: name
				path: action.params.get_default('path', '')!
				git_url: action.params.get_default('git_url', '')!
				git_reset: action.params.get_default_false('git_reset')
				git_pull: action.params.get_default_false('git_pull')
			)!

			sim.play(mut plbook)!
			simulator_set(sim)
		}
	}
}

pub fn (mut self Simulator) play(mut plbook PlayBook) ! {
	// make sure we know the inca price
	mut actions4 := plbook.actions_find(actor: 'tfgrid_simulator')!

	if actions4.len == 0 {
		return
	}
	self.nodes = cloudslices.play(mut plbook)!

	for mut action in actions4 {
		if action.name == 'incaprice_define' {
			mut incaprice := self.sheet.row_new(
				name: 'incaprice'
				growth: action.params.get_default('incaprice_usd', '0.1')!
				descr: '"INCA Price in USD'
				extrapolate: true
				aggregatetype: .avg
			)!
			for mycel in incaprice.cells {
				if f64(mycel.val) == 0.0 {
					return error('INCA price cannot be 0.')
				}
			}
		}
	}

	if 'incaprice' !in self.sheet.rows {
		return error("can't find incaprice_define action for tfgrid_simulator, needs to define INCA price.")
	}

	mut actions2 := plbook.actions_find(actor: 'tfgrid_simulator')!
	for action in actions2 {
		if action.name == 'node_growth_define' {
			mut node_name := action.params.get_default('node_name', '')!

			mut node := self.nodes[node_name] or {
				return error("can't find node in simulate with name: ${node_name}")
			}

			mut new_nodes_per_month := self.sheet.row_new(
				name: '${node_name}_new_per_month'
				growth: action.params.get('new_month')!
				tags: 'nrnodes_new nodetype:${node_name}'
				descr: '"new nodes we add per month for node type ${node_name}'
				extrapolate: true
				aggregatetype: .max
			)!

			println('new per month for ${node_name}:')
			println(new_nodes_per_month.cells)

			mut investment_nodes := new_nodes_per_month.copy(
				name: '${node_name}_investment_usd'
				tags: 'node_investment nodetype:${node_name}'
				descr: "investment needed for node type ${node_name}'"
			)!
			for mut cell in investment_nodes.cells {
				cell.val = cell.val * node.cost
			}

			mut churn := self.sheet.row_new(
				name: '${node_name}_churn'
				growth: action.params.get('churn')!
				tags: 'churn nodetype:${node_name}'
				descr: '"nr of nodes in percentage we loose per year for node type: ${node_name}'
				extrapolate: true
				aggregatetype: .avg
			)!

			mut utilization := self.sheet.row_new(
				name: '${node_name}_utilization'
				growth: action.params.get('utilization')!
				tags: 'utilization nodetype:${node_name}'
				descr: '"utilization in 0..100 percent for node type: ${node_name}'
				extrapolate: true
				aggregatetype: .avg
			)!

			mut discount := self.sheet.row_new(
				name: '${node_name}_discount'
				growth: action.params.get('discount')!
				tags: 'discount nodetype:${node_name}'
				descr: '"discount in 0..100 percent for node type: ${node_name}'
				extrapolate: true
				aggregatetype: .avg
			)!

			mut row_nr_nodes_total := new_nodes_per_month.recurring(
				name: '${node_name}_nr_active'
				delaymonths: 2
				tags: 'nrnodes_active nodetype:${node_name}'
				descr: '"nr nodes active for for node type: ${node_name}'
				aggregatetype: .max
			)!

			node_total := node.node_total()

			mut node_rev := self.sheet.row_new(
				name: '${node_name}_rev_month'
				growth: '${node_total.price_simulation}'
				tags: 'nodetype:${node_name}'
				descr: '"Sales price in USD per node of type:${node_name} per month (usd)'
				extrapolate: true
				aggregatetype: .sum
			)!

			mut node_rev_total := self.sheet.row_new(
				name: '${node_name}_rev_total'
				tags: 'noderev nodetype:${node_name}'
				descr: '"Sales price in USD total for node type: ${node_name} per month'
				aggregatetype: .sum
				growth: '1:0'
			)!

			// apply the sales price discount & calculate the sales price in total
			mut counter := 0
			for mut cell in node_rev.cells {
				discount_val := discount.cells[counter].val
				cell.val = cell.val * (1 - discount_val / 100) * utilization.cells[counter].val / 100
				node_rev_total.cells[counter].val = cell.val * row_nr_nodes_total.cells[counter].val
				counter += 1
			}

			// grant_month_usd:'1:60,24:60,25:0'
			// grant_month_inca:'1:0,24:0'
			// grant_max_nrnodes:1000 //max nr of nodes which will get this grant

			mut grant_node_month_usd := self.sheet.row_new(
				name: '${node_name}_grant_node_month_usd'
				descr: '"Grant in USD for node type: ${node_name}'
				aggregatetype: .sum
				growth: node.grant.grant_month_usd
			)!

			mut grant_node_month_inca := self.sheet.row_new(
				name: '${node_name}_grant_node_month_inca'
				descr: '"Grant in INCA for node type: ${node_name}'
				aggregatetype: .sum
				growth: node.grant.grant_month_inca
			)!

			mut inca_grant_node_month_inca := self.sheet.row_new(
				name: '${node_name}_grant_node_total'
				tags: 'incagrant'
				descr: '"INCA grant for node type: ${node_name}'
				aggregatetype: .sum
				growth: '0:0'
			)!
			mut counter2 := 0
			row_incaprice := self.sheet.rows['incaprice'] or {
				return error("can't find row incaprice")
			}
			for mut cell in inca_grant_node_month_inca.cells {
				grant_usd := grant_node_month_usd.cells[counter2].val
				grant_inca := grant_node_month_inca.cells[counter2].val
				mut nr_nodes := row_nr_nodes_total.cells[counter2].val
				if nr_nodes > node.grant.grant_max_nrnodes {
					nr_nodes = node.grant.grant_max_nrnodes
				}
				incaprice_now := f64(row_incaprice.cells[counter2].val)
				if incaprice_now == 0.0 {
					panic('bug incaprice_now cannot be 0')
				}
				// println(" nrnodes: ${nr_nodes} incaprice:${incaprice_now} grant_usd:${grant_usd} grant_inca:${grant_inca}")
				cell.val = nr_nodes * (grant_usd / incaprice_now + grant_inca)
				counter2 += 1
			}
			// println(inca_grant_node_month_inca.cells)    	
		}
	}

	// MAIN SIMULATION LOGIC

	incaprice := self.sheet.rows['incaprice'] or { return error("can't find row incaprice") }

	mut rev_usd := self.sheet.group2row(
		name: 'noderev'
		tags: 'nodestats_total'
		include: ['noderev']
		descr: 'revenue in USD from all nodes per month'
	)!

	mut investment_usd := self.sheet.group2row(
		name: 'investment'
		tags: 'nodestats_total'
		include: ['node_investment']
		descr: 'investment in USD from all nodes per month'
	)!

	// mut investment_usd := self.sheet.group2row(
	// 	name: 'investment_usd'
	// 	tags: 'total'
	// 	include: ['node_investment']
	// 	descr: 'investment in USD from all nodes per month'
	// )!

	simulator_set(self)

	// println(self.sheet)

	// if true{
	// 	panic("arym")
	// }
}
