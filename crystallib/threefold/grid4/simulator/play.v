module simulator

import freeflowuniverse.crystallib.core.playbook { PlayBook }
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.threefold.grid4.cloudslices
import freeflowuniverse.crystallib.biz.spreadsheet

pub fn play(mut plbook PlayBook) ! {

	mut sheet_name:=""
	//first make sure we find a run action to know the name
	mut actions4 := plbook.actions_find_by_name(actor: 'tfgrid4_simulator')!

	if actions4.len==0{
		return
	}

	for mut action in actions4 {
		if action.name == 'run' {	
			sheet_name = action.params.get('name')!
		}
	}	

	if sheet_name==""{
		return error("can't find run action for tfgrid4_simulator, name needs to be specified as arg.")
	}

	mut sh := spreadsheet.sheet_new(name:"tfgridsim_${sheet_name}")!
	mut sim := Simulator{
		sheet: &sh
		// currencies: cs
	}

	simulator_set(sim)

	sim.play(mut plbook)!

}

pub fn (mut self Simulator) play(mut plbook PlayBook) ! {	

	self.nodes = cloudslices.play(mut plbook)!

	//make sure we know the inca price
	mut actions4 := plbook.actions_find_by_name(actor: 'tfgrid4_simulator')!
	for mut action in actions4 {
		if action.name == 'incaprice_define' {
			mut incaprice := self.sheet.row_new(
				name: 'incaprice'
				growth: action.params.get('incaprice_usd')!
				descr: '"INCA Price in USD'
				extrapolate: true
				aggregatetype:.avg
			)!		

		}
	}	

	if ! ("incaprice" in self.sheet.rows){
		return error("can't find incaprice_define action for tfgrid4_simulator, needs to define INCA price.")
	}

	
	mut actions2 := plbook.actions_find_by_name(actor: 'tfgrid4_simulator')!
	for action in actions2 {
		if action.name == 'node_growth_define' {
			mut node_name := action.params.get_default('node_name', '')!

			mut node:=self.nodes[node_name] or {return error("can't find node in simulate with name: ${node_name}")}

			mut new_nodes_per_month := self.sheet.row_new(
				name: '${node_name}_new_per_month'
				growth: action.params.get("new_month")!
				tags: 'nrnodes_new'
				descr: '"new nodes we add per month for node type ${node_name}'
				extrapolate: true
				aggregatetype:.sum
			)!

			mut investment_nodes := new_nodes_per_month.copy(
					name:"${node_name}_investment_usd"
					tags:"node_investment"
					descr:"investment needed for node type ${node_name}'"
				)!
			for mut cell in investment_nodes.cells {
				cell.val = cell.val * node.cost
			}


			mut churn := self.sheet.row_new(
				name: '${node_name}_churn'
				growth: action.params.get("churn")!
				tags: 'churn'
				descr: '"nr of nodes in percentage we loose per year for node type: ${node_name}'
				extrapolate: true
				aggregatetype:.avg
			)!		

			mut utilization := self.sheet.row_new(
				name: '${node_name}_utilization'
				growth: action.params.get("utilization")!
				tags: 'utilization'
				descr: '"utilization in 0..100 percent for node type: ${node_name}'
				extrapolate: true
				aggregatetype:.avg
			)!			

			mut discount := self.sheet.row_new(
				name: '${node_name}_discount'
				growth: action.params.get("discount")!
				tags: 'discount'
				descr: '"discount in 0..100 percent for node type: ${node_name}'
				extrapolate: true
				aggregatetype:.avg
			)!

			mut row_nr_nodes_total := new_nodes_per_month.recurring(
				name:'${node_name}_nr_total'
				delaymonths:2
				tags: 'nrnodes_active'
				descr: '"nr nodes active for for node type: ${node_name}'
				aggregatetype: .sum
			)!

			node_total:=node.node_total()

			mut node_sales_price_unit := self.sheet.row_new(
					name: '${node_name}_sales_price_unit'
					growth: "${node_total.price_simulation}"
					tags: 'salespriceunit'
					descr: '"Sales price in USD per unit for: ${node_name}'
					extrapolate: true
					aggregatetype:.sum
				)!

			mut node_sales_price_tot := self.sheet.row_new(
					name: '${node_name}_revenue'
					tags: 'noderevenue'
					descr: '"Sales price in USD total for node type: ${node_name}'
					aggregatetype:.sum
					growth:"1:0"
				)!


			//apply the sales price discount & calculate the sales price in total
			mut counter:=0
			for mut cell in node_sales_price_unit.cells {
				discount_val := discount.cells[counter].val
				cell.val = cell.val * (1-discount_val/100)
				node_sales_price_tot.cells[counter].val = cell.val * row_nr_nodes_total.cells[counter].val * utilization.cells[counter].val / 100
				counter+=1
			}


			// grant_month_usd:'1:60,24:60,25:0'
			// grant_month_inca:'1:0,24:0'
			// grant_max_nrnodes:1000 //max nr of nodes which will get this grant
			

			mut grant_node_month_usd := self.sheet.row_new(
					name: '${node_name}_grant_node_month_usd'
					descr: '"Grant in USD for node type: ${node_name}'
					aggregatetype:.sum
					growth:node.grant.grant_month_usd
				)!

			mut grant_node_month_inca := self.sheet.row_new(
					name: '${node_name}_grant_node_month_inca'
					descr: '"Grant in INCA for node type: ${node_name}'
					aggregatetype:.sum
					growth:node.grant.grant_month_inca
				)!

			mut inca_grant_node_month_inca := self.sheet.row_new(
					name: '${node_name}_grant_node_total'
					tags: 'incagrant'
					descr: '"INCA grant for node type: ${node_name}'
					aggregatetype:.sum
					growth:"1:0"
				)!
			mut counter2:=0
			incaprice := self.sheet.rows["incaprice"] or {return error("can't find row incaprice")}
			for mut cell in inca_grant_node_month_inca.cells {
				grant_usd := grant_node_month_usd.cells[counter2].val
				grant_inca := grant_node_month_inca.cells[counter2].val
				mut nr_nodes := row_nr_nodes_total.cells[counter2].val
				if nr_nodes>node.grant.grant_max_nrnodes{
					nr_nodes=node.grant.grant_max_nrnodes
				}
				incaprice_now := incaprice.cells[counter2].val
				cell.val = nr_nodes*(grant_usd/incaprice_now + grant_inca)
				counter+=1
			}
    	
		}
	}

	//MAIN SIMULATION LOGIC

	incaprice := self.sheet.rows["incaprice"] or {return error("can't find row incaprice")}


	mut rev_usd:=self.sheet.group2row(
			name:"revenue_usd"
			tags:"total"
			include: ['noderevenue']
			descr:"revenue in USD from all nodes per month"
			)!

	mut rev_inca := rev_usd.action(
			name:"revenue_inca"
			tags:"total"
			descr:"revenue in INCA from all nodes per month"
			action:.divide
			rows: [incaprice]
		)!

	mut investment_usd:=self.sheet.group2row(
			name:"investment_usd"
			tags:"total"
			include: ['node_investment']
			descr:"investment in USD from all nodes per month"
			)!



	simulator_set(self)

	// println(self.sheet)

	// if true{
	// 	panic("arym")
	// }


}
