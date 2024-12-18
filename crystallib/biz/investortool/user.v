module investortool

import freeflowuniverse.crystallib.core.playbook

@[heap]
pub struct User {
pub mut:
	oid          string
	usercode     string
	name         string
	investor_ids []string
	status       string
	info_links   []string
	telnrs       []string
	emails       []string
	secret       string
}

fn play_user(mut investortool InvestorTool, mut plbook playbook.PlayBook) ! {
	for mut action in plbook.find(filter: 'investortool.user_define')! {
		mut p := action.params
		mut user := User{
			oid:          p.get_default('oid', '')!
			usercode:     p.get_default('usercode', '')!
			name:         p.get_default('name', '')!
			investor_ids: p.get_list_default('investor_ids', [])!
			status:       p.get_default('status', '')!
			info_links:   p.get_list_default('info_links', [])!
			telnrs:       p.get_telnrs_default('telnrs', [])!
			emails:       p.get_emails_default('emails', [])!
			secret:       p.get_default('secret', '')!
		}
		// println(user)
		investortool.user_add(user)!
		// TODO: now we need to do some mapping to make sure telnr's and emails are normalized (no . in tel nr, no spaces ...)
	}
}
