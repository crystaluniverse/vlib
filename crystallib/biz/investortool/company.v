module investortool

import freeflowuniverse.crystallib.core.playbook

@[heap]
pub struct Company {
pub mut:
	oid                 string
	short_code          string
	name                string
	current_nr_shares   int
	current_share_value string
	description         string
	admins              []string
	comments            []string
}

fn play_company(mut investortool InvestorTool, mut plbook playbook.PlayBook) ! {
	for mut action in plbook.find(filter: 'investortool.company_define')! {
		mut p := action.params
		mut company := Company{
			oid:                 p.get_default('oid', '')!
			short_code:          p.get_default('short_code', '')!
			name:                p.get_default('name', '')!
			current_nr_shares:   p.get_int_default('current_nr_shares', 0)!
			current_share_value: p.get_default('current_share_value', '')!
			description:         p.get_default('description', '')!
			admins:              p.get_list_default('admins', [])!
			comments:            p.get_list_default('comments', [])!
		}
		println(company)
		investortool.company_add(company)!
	}
}
