module ufw

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.data.paramsparser

pub fn play_ufw(mut plbook playbook.PlayBook) !RuleSet {
	mut ufw_status := UFWStatus{
		active: false
		rules:  []
	}

	mut ruleset := RuleSet{}

	// Find all UFW-related actions
	ufw_actions := plbook.find(filter: 'ufw.')!
	if ufw_actions.len == 0 {
		return
	}

	for action in ufw_actions {
		mut p := action.params

		match action.name {
			'ufw.configure' {
				ufw_status.active = p.get_default_true('active')!
				ruleset.ssh = p.get_default_true('ssh')!
				ruleset.reset = p.get_default_true('reset')!
			}
			'ufw.add_rule' {
				mut rule := Rule{
					allow: p.get_default_true('allow')!
					port:  p.get_int('port')!
					from:  p.get_default('from', 'any')!
					tcp:   p.get_default_true('tcp')!
					udp:   p.get_default('udp', false)!
					ipv6:  p.get_default('ipv6', false)!
				}
				ruleset.rules << rule
			}
			else {
				println('Unknown action: ${action.name}')
			}
		}
	}
	return ruleset
}
