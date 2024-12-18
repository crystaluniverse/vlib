module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import rand

fn (mut t TFGridHandler) discourse(action Action) ! {
	match action.name {
		'create' {
			name := action.params.get_default('name', rand.string(10).to_lower())!
			farm_id := action.params.get_int_default('farm_id', 0)!
			capacity := action.params.get_default('capacity', 'medium')!
			ssh_key_name := action.params.get_default('ssh_key', 'default')!
			ssh_key := t.get_ssh_key(ssh_key_name)!
			developer_email := action.params.get_default('developer_email', '')!
			smtp_address := action.params.get_default('smtp_address', 'smtp.gmail.com')!
			smtp_port := action.params.get_int_default('smtp_port', 587)!
			smtp_username := action.params.get_default('smtp_username', '')!
			smtp_password := action.params.get_default('smtp_password', '')!
			smtp_tls := action.params.get_default_false('smtp_tls')

			deploy_res := t.tfgrid.deploy_discourse(
				name:            name
				farm_id:         u64(farm_id)
				capacity:        capacity
				ssh_key:         ssh_key
				developer_email: developer_email
				smtp_address:    smtp_address
				smtp_port:       u32(smtp_port)
				smtp_username:   smtp_username
				smtp_password:   smtp_password
				smtp_enable_tls: smtp_tls
			)!

			t.logger.info('${deploy_res}')
		}
		'get' {
			name := action.params.get('name')!

			get_res := t.tfgrid.get_discourse_deployment(name)!

			t.logger.info('${get_res}')
		}
		'delete' {
			name := action.params.get('name')!

			t.tfgrid.cancel_discourse_deployment(name) or {
				return error('failed to delete discourse instance: ${err}')
			}
		}
		else {
			return error('operation ${action.name} is not supported on discourse')
		}
	}
}
