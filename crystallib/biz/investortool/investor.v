module investortool

import freeflowuniverse.crystallib.core.playbook

@[heap]
pub struct Investor {
pub mut:
	oid         string
	name        string
	code        string
	description string
	user_refs   []string
	admins      []string
	comments    []string
}

fn play_investor(mut investortool InvestorTool, mut plbook playbook.PlayBook) ! {
	for mut action in plbook.find(filter: 'investortool.investor_define')! {
		mut p := action.params
		mut investor := Investor{
			oid:         p.get_default('oid', '')!
			name:        p.get_default('name', '')!
			code:        p.get_default('code', '')!
			description: p.get_default('description', '')!
			user_refs:   p.get_list_default('user_refs', [])!
			admins:      p.get_list_default('admins', [])!
			comments:    p.get_list_default('comments', [])!
		}
		// println(investor)

		investortool.investor_add(investor)!
	}
}
