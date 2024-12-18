module main

import freeflowuniverse.crystallib.osal { exec }

fn do() ! {
	exec(
		cmd:   'eecho sometext'
		retry: 5
	) or {
		println(err.code())
		assert err.code() == 127
	}
	// should print code 127

	exec(
		cmd:                'eecho sometext'
		ignore_error_codes: [127]
		retry:              5
	)!

	r := exec(
		cmd:                'echo sometext'
		ignore_error_codes: [127]
		retry:              5
	)!

	println(r)

	// _ := exec(
	// 	cmd: 'mc'
	// 	path: "/tmp/test.sh"
	// 	environment:{
	// 		"TEST":"HI"
	// 		"YES":"no"
	// 	}
	// 	shell: true
	// 	debug:true
	// )!

	println('echo ok ')
}

fn main() {
	do() or { panic(err) }
}
