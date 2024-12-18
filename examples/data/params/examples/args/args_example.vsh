#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.data.paramsparser
import os

const testpath = os.dir(@FILE) + '/data'

ap := playbook.new(path: testpath)!

mut test := map[string]string{}
test['root'] = 'YEH'
test['roott'] = 'YEH2'
for action in ap.actions {
	// action.params.replace(test)
	mut p := action.params
	p.replace(test)
	println(p)
}

txt := '

this is a text \${aVAR}

this is a text \${aVAR}

\${A}

'
// println(txt)
// println(params.regexfind(txt))
