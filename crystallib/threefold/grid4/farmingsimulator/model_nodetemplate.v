module farmingsimulator

// is a template which can be used for deploying threefold nodes
// a component group describes which components make up the node template
@[heap]
pub struct NodeTemplate {
pub mut:
	name       string
	components []ComponentGroup
	capacity   FarmingCapacity // the result for this node template
}

// as used in node template
pub struct ComponentGroup {
pub mut:
	name      string
	nr        int // nr of components
	component Component
}

// is a component as used to create a node template
// see https://library.threefold.me/info/threefold/#/tfgrid/resource_units
pub struct Component {
pub mut:
	name        string
	description string
	cost        f64 // cost always in USD
	rackspace   f64 // expressed in U, typical rack has 44 units
	power       f64 // expressed in watt
	cru         f64 // 1 logical core
	mru         f64 // 1 GB of memory
	hru         f64 // 1 GB of HD
	sru         f64 // 1 GB of SSD
}

// a node template, holds the construction of a node as used in a grid
pub fn node_template_new(name string) NodeTemplate {
	return NodeTemplate{
		capacity: FarmingCapacity{}
	}
}

pub struct ComponentGroupArgs {
pub mut:
	nr        int // nr of components
	component Component
}

pub fn (mut nt NodeTemplate) components_add(cg ComponentGroupArgs) {
	nt.components << ComponentGroup{
		name:      cg.component.name
		nr:        cg.nr
		component: cg.component
	}
	nt.calc()
}

// recalculate the totals of the template
fn (mut nt NodeTemplate) calc() {
	mut fc := FarmingCapacity{}
	for cg in nt.components {
		fc.cost += cg.component.cost * cg.nr
		fc.rackspace += cg.component.rackspace * cg.nr
		fc.power += cg.component.power * cg.nr
		fc.resourceunits.cru += cg.component.cru * cg.nr
		fc.resourceunits.mru += cg.component.mru * cg.nr
		fc.resourceunits.hru += cg.component.hru * cg.nr
		fc.resourceunits.sru += cg.component.sru * cg.nr
	}
	fc.cloudunits = cloudunits_calc(fc.resourceunits) // calculate the cloudunits
	nt.capacity = fc
}

// //define a template node
// cpu_amd_gr9 := sim.Component{
// 	name: "AMD32"
// 	description: "powerful amd cpu"
// 	cost:250.0
// 	power:70
// 	cru:32
// }	
// case1u := sim.Component{
// 	name: "case_1u"
// 	description: "1U rack mountable case"
// 	cost:150.0
// 	rackspace:1
// 	power:20
// }	
// mem32 := sim.Component{
// 	name: "32GB"
// 	description: "memory 32 GB"
// 	cost:90.0
// 	power:20
// 	mru:32
// }
// ssd1 := sim.Component{
// 	name: "ssd2gb"
// 	description: "SSD of 1 GB"
// 	cost:120.0
// 	power:5
// 	sru:2000
// }			

// //lets populate our template
// mut node_1u_template := sim.node_template_new("1u")
// node_1u_template.components_add(nr:1,component:case1u) //add case
// node_1u_template.components_add(nr:1,component:cpu_amd_gr9) //add CPU
// node_1u_template.components_add(nr:4,component:mem32) //add mem
// node_1u_template.components_add(nr:2,component:ssd1) //add ssd
