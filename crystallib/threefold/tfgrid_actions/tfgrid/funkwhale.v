module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import rand

fn (mut t TFGridHandler) funkwhale(action Action) ! {
	match action.name {
		'create' {
			name := action.params.get_default('name', rand.string(10).to_lower())!
			farm_id := action.params.get_int_default('farm_id', 0)!
			capacity := action.params.get_default('capacity', 'meduim')!
			ssh_key_name := action.params.get_default('ssh_key', 'default')!
			ssh_key := t.get_ssh_key(ssh_key_name)!
			admin_email := action.params.get('admin_email')!
			admin_username := action.params.get_default('admin_username', '')!
			admin_password := action.params.get_default('admin_password', '')!

			deploy_res := t.tfgrid.deploy_funkwhale(
				name:           name
				farm_id:        u64(farm_id)
				capacity:       capacity
				ssh_key:        ssh_key
				admin_email:    admin_email
				admin_username: admin_username
				admin_password: admin_password
			)!

			t.logger.info('${deploy_res}')
		}
		'get' {
			name := action.params.get('name')!

			get_res := t.tfgrid.get_funkwhale_deployment(name)!

			t.logger.info('${get_res}')
		}
		'delete' {
			name := action.params.get('name')!

			t.tfgrid.cancel_funkwhale_deployment(name) or {
				return error('failed to delete funkwhale instance: ${err}')
			}
		}
		else {
			return error('operation ${action.name} is not supported on funkwhale')
		}
	}
}
