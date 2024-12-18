module cloudslices

import freeflowuniverse.crystallib.core.playbook { PlayBook }

// this play script should never be called from hero directly its called by gridsimulator
pub fn play(mut plbook PlayBook) !map[string]&Node {
	mut actions2 := plbook.actions_find(actor: 'tfgrid_simulator')!

	mut nodesdict := map[string]&Node{}
	for action in actions2 {
		if action.name == 'node_define' {
			mut name := action.params.get_default('name', '')!
			mut node := Node{
				grant: NodeGrant{}
			}

			nodesdict[name] = &node

			node.cpu_brand = action.params.get_default('cpu_brand', '')!
			node.cpu_version = action.params.get_default('cpu_version', '')!
			// node.deliverytime = action.params.get_default('deliverytime', '')!
			node.description = action.params.get_default('description', '')!
			node.hdd = action.params.get_default('hdd', '')!
			node.image = action.params.get_default('image', '')!
			node.inca_reward = action.params.get_int('inca_reward')!
			node.mem = action.params.get_default('mem', '')!
			node.passmark = action.params.get_int_default('passmark', 0)!
			node.cost = action.params.get_float('cost')! // This is required
			node.ssd = action.params.get_default('ssd', '')!
			node.url = action.params.get_default('url', '')!
			node.vendor = action.params.get_default('vendor', '')!

			// get the grants
			node.grant.grant_month_usd = action.params.get('grant_month_usd') or { '' }
			node.grant.grant_month_inca = action.params.get('grant_month_inca') or { '' }
			node.grant.grant_max_nrnodes = action.params.get_int('grant_max_nrnodes') or { 0 }
		}
	}
	// now all nodes are defined lets now do the sub parts
	for action in actions2 {
		if action.name == 'cloudbox_define' {
			mut node_name := action.params.get('node')! // needs to be specified
			mut node := nodesdict[node_name] or {
				return error("can't find node with name: ${node_name}")
			}

			mut subobj := CloudBox{
				amount:           action.params.get_int_default('amount', 1)!
				description:      action.params.get_default('description', '')!
				ssd_nr:           action.params.get_int_default('ssd_nr', 1)!
				storage_gb:       action.params.get_float('storage_gb')! // required
				passmark:         action.params.get_int_default('passmark', 1)!
				vcores:           action.params.get_int('vcores')!
				mem_gb:           action.params.get_float('mem_gb')!
				price_range:      action.params.get_list_f64('price_range')!
				price_simulation: action.params.get_float('price_simulation')!
			}

			if subobj.price_range.len != 2 {
				return error('price range needs to be 2 elements for \n${subobj}')
			}
			if subobj.price_simulation == 0.0 {
				return error('price_simulation needs to be specified for \n${subobj}')
			}

			node.cloudbox << subobj
		}

		if action.name == 'storagebox_define' {
			mut node_name := action.params.get('node')! // needs to be specified
			mut node := nodesdict[node_name] or {
				return error("can't find node with name: ${node_name}")
			}

			mut subobj := StorageBox{
				amount:           action.params.get_int_default('amount', 1)!
				description:      action.params.get_default('description', '')!
				price_range:      action.params.get_list_f64('price_range')!
				price_simulation: action.params.get_float('price_simulation')!
			}

			if subobj.price_range.len != 2 {
				return error('price range needs to be 2 elements for \n${subobj}')
			}
			if subobj.price_simulation == 0.0 {
				return error('price_simulation needs to be specified for \n${subobj}')
			}
			node.storagebox << subobj
		}

		if action.name == 'aibox_define' {
			mut node_name := action.params.get('node')! // needs to be specified
			mut node := nodesdict[node_name] or {
				return error("can't find node with name: ${node_name}")
			}

			mut subobj := AIBox{
				amount:           action.params.get_int_default('amount', 1)!
				description:      action.params.get_default('description', '')!
				ssd_nr:           action.params.get_int_default('ssd_nr', 1)!
				storage_gb:       action.params.get_float('storage_gb')! // required
				mem_gb_gpu:       action.params.get_float('mem_gb_gpu')!
				passmark:         action.params.get_int_default('passmark', 1)!
				vcores:           action.params.get_int('vcores')!
				mem_gb:           action.params.get_float('mem_gb')!
				price_range:      action.params.get_list_f64('price_range')!
				price_simulation: action.params.get_float('price_simulation')!
				gpu_brand:        action.params.get_default('gpu_brand', '')!
				gpu_version:      action.params.get_default('gpu_version', '')!
			}

			if subobj.price_range.len != 2 {
				return error('price range needs to be 2 elements for \n${subobj}')
			}
			if subobj.price_simulation == 0.0 {
				return error('price_simulation needs to be specified for \n${subobj}')
			}

			node.aibox << subobj
		}
	}
	return nodesdict
}
