module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid as tfgrid_client { GatewayFQDN }
import rand

fn (mut t TFGridHandler) gateway_fqdn(action Action) ! {
	match action.name {
		'create' {
			node_id := action.params.get_int('node_id')!
			name := action.params.get_default('name', rand.string(10).to_lower())!
			tls_passthrough := action.params.get_default_false('tls_passthrough')
			backend := action.params.get('backend')!
			fqdn := action.params.get('fqdn')!

			gw_deploy := t.tfgrid.deploy_gateway_fqdn(GatewayFQDN{
				name:            name
				node_id:         u32(node_id)
				tls_passthrough: tls_passthrough
				backends:        [backend]
				fqdn:            fqdn
			})!

			t.logger.info('${gw_deploy}')
		}
		'delete' {
			name := action.params.get('name')!
			t.tfgrid.cancel_gateway_fqdn(name)!
		}
		'get' {
			name := action.params.get('name')!
			gw_get := t.tfgrid.get_gateway_fqdn(name)!

			t.logger.info('${gw_get}')
		}
		else {
			return error('action ${action.name} is not supported on gateways')
		}
	}
}
