module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid as tfgrid_client { GatewayName }
import rand

fn (mut t TFGridHandler) gateway_name(action Action) ! {
	match action.name {
		'create' {
			node_id := action.params.get_int_default('node_id', 0)!
			name := action.params.get_default('name', rand.string(10).to_lower())!
			tls_passthrough := action.params.get_default_false('tls_passthrough')
			backend := action.params.get('backend')!

			gw_deploy := t.tfgrid.deploy_gateway_name(GatewayName{
				name:            name
				node_id:         u32(node_id)
				tls_passthrough: tls_passthrough
				backends:        [backend]
			})!

			t.logger.info('${gw_deploy}')
		}
		'delete' {
			name := action.params.get('name')!
			t.tfgrid.cancel_gateway_name(name)!
		}
		'get' {
			name := action.params.get('name')!
			gw_get := t.tfgrid.get_gateway_name(name)!

			t.logger.info('${gw_get}')
		}
		else {
			return error('action ${action.name} is not supported on gateways')
		}
	}
}
