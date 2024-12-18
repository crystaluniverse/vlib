module playbook

import os
import crypto.sha256
import freeflowuniverse.crystallib.ui.console

const testpath = os.dir(@FILE) + '/testdata'

// TODO: fix

const text1 = "
//comment for the action
!!payment.add person:fatayera
	//comment for name
	name: 'TF Wallet'
	blockchain: 'stellar' //holochain maybe?
	account: 'something'
	description: 'TF Wallet for TFT' 
	preferred: false

//comment2
!!payment.add person:despiegk
	name: 'TF Wallet2'

"

const text2 = "
//comment for the action
!!payment.add person:fatayera
	name: 'TF Wallet'

!!payment.else person:despiegk
	name: 'TF Wallet2'

!!actor2.else person:despiegk
	name: 'TF Wallet2'

"

fn test_parse_1() {
	mut a := new(text: text1) or { panic(err) }

	console.print_debug('${a}')

	console.print_debug("EXPECTED OUTPUT:
// comment for the action
!!payment.add account:something description:'TF Wallet for TFT' person:fatayera preferred:false
	name:'TF Wallet' //comment for name
	blockchain:stellar //holochain maybe?

// comment2
!!payment.add name:'TF Wallet2' person:despiegk
")

	assert sha256.hexhash(a.str()) == 'e86eb063d8556c8501f63494a863fc78415112d6990ba6f1d0d5db16ff26e954'
}

fn test_hashkey() {
	mut a := new(text: text1) or { panic(err) }
	t := a.hashkey()

	console.print_debug(t)

	assert t == 'a5e85c3a8e4c132bd40c88acc0dcc3d9a2af56c5'
}

fn test_filter() {
	mut a := new(text: text2) or { panic(err) }

	mut b := a.find(filter: 'payment.*')!
	assert b.len == 2

	mut c := a.find(filter: 'payment.else')!
	assert c.len == 1

	mut d := a.find(filter: 'actor2.*')!
	assert d.len == 1

	mut e := a.find(filter: 'actor2.else')!
	assert e.len == 1

	mut f := a.find(filter: 'actor2:else2')!
	assert f.len == 0
}
