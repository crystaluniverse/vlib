module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid as tfgrid_client { ZDBDeployment }
import rand

fn (mut t TFGridHandler) zdb(action Action) ! {
	match action.name {
		'create' {
			node_id := action.params.get_int_default('node_id', 0)!
			name := action.params.get_default('name', rand.string(10).to_lower())!
			password := action.params.get_default('password', rand.string(10).to_lower())!
			public := action.params.get_default_false('public')
			size := action.params.get_storagecapacity_in_gigabytes('size') or { 10 }
			mode := action.params.get_default('mode', 'user')!

			zdb_deploy := t.tfgrid.deploy_zdb(ZDBDeployment{
				node_id:  u32(node_id)
				name:     name
				password: password
				public:   public
				size:     u32(size)
				mode:     mode
			})!

			t.logger.info('${zdb_deploy}')
		}
		'delete' {
			name := action.params.get('name')!
			t.tfgrid.cancel_zdb_deployment(name)!
		}
		'get' {
			name := action.params.get('name')!
			zdb_get := t.tfgrid.get_zdb_deployment(name)!

			t.logger.info('${zdb_get}')
		}
		else {
			return error('action ${action.name} is not supported on zdbs')
		}
	}
}
