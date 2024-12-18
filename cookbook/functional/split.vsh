#!/usr/bin/env -S v -n -w -enable-globals run

import os
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.installers.base

pub fn cleanit(item_ map[string]string) map[string]string {
	mut item := item_.clone()
	item['state'] = item['state'].trim('() ').to_lower()
	return item
}

assert '  my last\tname and first name'.fields() == ['my', 'last', 'name', 'and', 'first', 'name']
assert '  \tmy last\tname and first name   \t   \n'.fields() == ['my', 'last', 'name', 'and', 'first',
	'name']

assert texttools.to_array("\n Something,'else'  ,yes\n").map(it.to_lower()) == [
	'something',
	'else',
	'yes',
]

r0 := texttools.split_smart("'root'   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 /usr/sbin/distnoted\n \n",
	'')
assert ['root', '304', '0.0', '0.0', '408185328', '1360', '??', 'S', '16Dec23', '0:34.06',
	'/usr/sbin/distnoted'] == r0

r := texttools.to_map('name,-,-,-,-,pid,-,-,-,-,path', 'root   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 /usr/sbin/distnoted\n \n',
	'')
assert {
	'name': 'root'
	'pid':  '1360'
	'path': '/usr/sbin/distnoted'
} == r

r2 := texttools.to_map('name,-,-,-,-,pid,-,-,-,-,path', 'root   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 /usr/sbin/distnoted anotherone anotherone\n \n',
	'')
assert {
	'name': 'root'
	'pid':  '1360'
	'path': '/usr/sbin/distnoted'
} == r2

r3 := texttools.to_map('name,-,-,-,-,pid,-,-,-,-,path', 'root   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 \n \n',
	'')
assert {
	'name': 'root'
	'pid':  '1360'
	'path': ''
} == r3

t := '
_cmiodalassistants   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 /usr/sbin/distnoted agent
_locationd         281   0.0  0.0 408185328   1344   ??  S    16Dec23   0:35.80 /usr/sbin/distnoted agent

	root               275   0.0  0.0 408311904   7296   ??  Ss   16Dec23   2:00.56 /usr/libexec/storagekitd
_coreaudiod        268   0.0  0.0 408185328   1344   ??  S    16Dec23   0:35.49 /usr/sbin/distnoted agent
'

r4 := texttools.to_list_map('name,-,-,-,-,pid,-,-,-,-,path', t, '')
assert [{
	'name': '_cmiodalassistants'
	'pid':  '1360'
	'path': '/usr/sbin/distnoted'
}, {
	'name': '_locationd'
	'pid':  '1344'
	'path': '/usr/sbin/distnoted'
}, {
	'name': 'root'
	'pid':  '7296'
	'path': '/usr/libexec/storagekitd'
}, {
	'name': '_coreaudiod'
	'pid':  '1344'
	'path': '/usr/sbin/distnoted'
}] == r4

t2 := '
	11849.mysession	(Detached)
	17633.tracker	(Detached)
	7414.ttys003.KDSPRO	(Detached)
'

r5 := texttools.to_list_map('pre,state', t2, '').map(cleanit(it))
assert [{
	'pre':   '11849.mysession'
	'state': 'detached'
}, {
	'pre':   '17633.tracker'
	'state': 'detached'
}, {
	'pre':   '7414.ttys003.KDSPRO'
	'state': 'detached'
}] == r5
