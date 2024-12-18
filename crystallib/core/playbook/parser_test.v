module playbook

const text1 = "
//comment for the action
!!payment.add person:fatayera
	//comment for name
	name: 'TF Wallet'
	blockchain: 'stellar' //holochain maybe?
	account: 'something'
	description: 'TF Wallet for TFT' 
	preferred: false
"

fn test_parse_1() {
	mut a := new(text: text1) or { panic(err) }

	assert a.actions.len == 1
	mut s := a.actions_sorted()!
	assert s.len == 1
	// mut sorted := a.actions_sorted(prio_only: true)!
	// assert sorted.len == 0

	mut myaction := s[0] or { panic('bug') }

	assert myaction.comments == 'comment for the action'
	assert myaction.params.params.len == 6
	assert myaction.id == 1

	assert a.hashkey() == '95c585c8bf01b4c432cb7096dc7c974fc1a14b5a'
	c := a.heroscript()!
	b := new(text: c) or { panic(err) }

	assert b.hashkey() == '95c585c8bf01b4c432cb7096dc7c974fc1a14b5a'
}

fn test_parser() {
	mut pb := new(text: text1) or { panic(err) }
	mut a := pb.actions[0]
	assert a.actor == 'payment'
	assert a.name == 'add'
	assert a.params.get('name')! == 'TF Wallet'
	assert a.params.get('blockchain')! == 'stellar'
	assert a.params.get('account')! == 'something'
	assert a.params.get('description')! == 'TF Wallet for TFT'
	assert a.params.get_default_false('preferred') == false
}

fn test_parser2() {
	mut pb := new(
		text: "!!play.run url:'https://git.ourworld.tf/despiegk/cfg/src/branch/main/myit/hetzner.md'"
	) or { panic(err) }
	mut a := pb.actions[0]
	assert a.actor == 'play'
	assert a.name == 'run'
	assert a.params.get('url')! == 'https://git.ourworld.tf/despiegk/cfg/src/branch/main/myit/hetzner.md'
}
