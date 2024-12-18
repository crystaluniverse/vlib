module farmingsimulator

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.playbook { PlayBook }
// import freeflowuniverse.crystallib.threefold.grid4.farmingsimulator

pub fn play(mut plbook PlayBook) ! {
	// mut sheet_name := ''
	// first make sure we find a run action to know the name

	mut my_actions := plbook.actions_find(actor: 'tfgridsimulation_farming')!

	if my_actions.len == 0 {
		return
	}

	mut name := ''
	// console.print_header("AAAA")
	// console.print_debug(plbook)
	// console.print_header("BBBB")

	for mut action in my_actions {
		if action.name == 'run' {
			mut sim := new(
				name:      action.params.get_default('name', 'default')!
				path:      action.params.get_default('path', '')!
				git_url:   action.params.get_default('git_url', '')!
				git_reset: action.params.get_default_false('git_reset')
				git_pull:  action.params.get_default_false('git_pull')
			)!
			console.print_header('run the grid farming simulator')
			sim.play(mut plbook)!
			simulator_set(sim)
			console.print_debug('done')
		}
	}
}

pub fn (mut s Simulator) play(mut plbook PlayBook) ! {
	mut actions2 := plbook.actions_find(actor: 'tfgridsimulation_farming')!

	if actions2.len == 0 {
		// means nothing to do return quickly
		return
	}

	for action_nt in actions2 {
		// ADD THE NODE TEMPLATES
		if action_nt.name == 'component_define' {
			mut c_name := action_nt.params.get_default('name', '')!
			c_name = c_name.to_lower()
			mut c_description := action_nt.params.get_default('description', '')!
			mut c_cost := action_nt.params.get_float('cost')!
			mut rackspace := action_nt.params.get_float_default('rackspace', 0)!
			mut power := action_nt.params.get_float_default('power', 0)!
			mut cru := action_nt.params.get_float_default('cru', 0)!
			mut mru := action_nt.params.get_float_default('mru', 0)!
			mut hru := action_nt.params.get_float_default('hru', 0)!
			mut sru := action_nt.params.get_float_default('sru', 0)!
			mut component := Component{
				name:        c_name
				description: c_description
				cost:        c_cost
				rackspace:   rackspace
				power:       power
				cru:         cru
				mru:         mru
				hru:         hru
				sru:         sru
			}
			s.components[c_name] = &component
		}
		if action_nt.name == 'node_template_define' {
			mut nt_name := action_nt.params.get('name')!
			nt_name = nt_name.to_lower()
			mut node_template := node_template_new(nt_name)
			s.node_templates[nt_name] = &node_template
		}
		if action_nt.name == 'node_template_component_add' {
			mut comp_templ_name := action_nt.params.get('name')!
			mut comp_name := action_nt.params.get('component')!
			mut comp_nr := action_nt.params.get_int('nr')!
			comp_templ_name = comp_templ_name.to_lower()
			comp_name = comp_name.to_lower()
			mut node_template := s.node_templates[comp_templ_name] or {
				return error("Cannot find node template: '${comp_templ_name}', has it been defined?")
			}
			component := s.components[comp_name] or {
				return error("Cannot find component: '${comp_name}', has it been defined?")
			}
			node_template.components_add(nr: comp_nr, component: component)
		}
	}

	// NOW ADD THE REGIONAL INTERNETS
	mut actions3 := plbook.actions_find(actor: 'tfgridsimulation_farming')!
	for action_ri in actions3 {
		if action_ri.name == 'regional_internet_add' {
			mut iname := action_ri.params.get('name')!
			s.regionalinternet_add(iname)!
		}
		if action_ri.name == 'regional_internet_nodes_add' {
			mut ri_name := action_ri.params.get('name')!
			mut ri_template := action_ri.params.get('template')!
			mut ri_t_growth := action_ri.params.get('growth')!
			mut ri := s.regionalinternet_get(ri_name)!
			mut template := s.nodetemplate_get(ri_template)!
			ri.nodes_add(template: template, growth: ri_t_growth)!
		}
	}

	// now do the simulation, run it
	mut actions4 := plbook.actions_find(actor: 'tfgridsimulation_farming')!
	for action_ri in actions4 {
		if action_ri.name == 'regional_internet_add' {
			mut iname := action_ri.params.get('name')!
			s.regionalinternet_add(iname)!
		}
	}

	for _, mut ri in s.regional_internets {
		ri.calc()!
	}

	simulator_set(s)
}
