module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import rand

fn (mut t TFGridHandler) taiga(action Action) ! {
	match action.name {
		'create' {
			name := action.params.get_default('name', rand.string(8).to_lower())!
			farm_id := action.params.get_int_default('farm_id', 0)!
			capacity := action.params.get_default('capacity', 'meduim')!
			ssh_key_name := action.params.get_default('sshkey', 'default')!
			ssh_key := t.get_ssh_key(ssh_key_name)!
			admin_username := action.params.get('admin_username')!
			admin_password := action.params.get('admin_password')!
			admin_email := action.params.get('admin_email')!
			disk_size := action.params.get_storagecapacity_in_gigabytes('disk_size') or { 50 }

			deploy_res := t.tfgrid.deploy_taiga(
				name:           name
				farm_id:        u64(farm_id)
				capacity:       capacity
				ssh_key:        ssh_key
				admin_username: admin_username
				admin_password: admin_password
				admin_email:    admin_email
				disk_size:      u32(disk_size)
			)!

			t.logger.info('${deploy_res}')
		}
		'get' {
			name := action.params.get('name')!

			get_res := t.tfgrid.get_taiga_deployment(name)!

			t.logger.info('${get_res}')
		}
		'delete' {
			name := action.params.get('name')!

			t.tfgrid.cancel_taiga_deployment(name) or {
				return error('failed to delete taiga instance: ${err}')
			}
		}
		else {
			return error('operation ${action.name} is not supported on taiga')
		}
	}
}
