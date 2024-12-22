module farmingsimulator

// import freeflowuniverse.crystallib.calc

// X nr of nodes who are added in 1 month
struct NodesBatch {
pub mut:
	node_template     &NodeTemplate @[str: skip]
	nrnodes           int
	start_month       int
	nrmonths          int
	hw_cost           f64
	regional_internet &RegionalInternet @[str: skip]
}

struct NBCalc {
pub mut:
	power_kwh      int
	tokens_farmed  f64
	rackspace      f64
	power_cost     f64
	rackspace_cost f64
	hw_cost        f64
	support_cost   f64
	nrnodes        f64
}

fn (mut nb NodesBatch) calc(month int) !NBCalc {
	mut ri := nb.regional_internet

	power_kwh := nb.node_template.capacity.power * 24 * 30 / 1000 * nb.nrnodes
	rackspace := nb.node_template.capacity.rackspace * nb.nrnodes
	_ := ri.simulator.params
	tokens_farmed := ri.token_farming(nb.node_template, month)!

	if month < nb.start_month {
		return NBCalc{}
	}
	if month > nb.start_month + nb.nrmonths {
		return NBCalc{}
	}

	mut cost_power_unit_row := ri.sheet.row_get('cost_power')!
	mut rackspace_cost_unit_row := ri.sheet.row_get('rackspace_cost_unit')!
	mut support_cost_node_row := ri.sheet.row_get('support_cost_node')!

	cost_power_unit := cost_power_unit_row.cells[month].val
	rackspace_cost_unit := rackspace_cost_unit_row.cells[month].val
	support_cost_node := support_cost_node_row.cells[month].val

	nbc := NBCalc{
		power_kwh:      int(power_kwh)
		power_cost:     power_kwh * cost_power_unit
		rackspace:      rackspace
		rackspace_cost: rackspace * rackspace_cost_unit
		hw_cost:        nb.hw_cost / 6 / 12 * nb.nrnodes // over 6 years
		support_cost:   support_cost_node + nb.node_template.capacity.cost * 0.02 / 12 * nb.nrnodes // 2% of HW has to be replaced
		tokens_farmed:  tokens_farmed * nb.nrnodes
		nrnodes:        nb.nrnodes
	}

	return nbc
}
