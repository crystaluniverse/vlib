#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.lang.python
import json

pub struct Person {
	name      string
	age       int
	is_member bool
	skills    []string
}

mut py := python.new(name: 'test')! // a python env with name test
// py.update()!
py.pip('ipython')!

nrcount := 5
cmd := $tmpl('pythonexample.py')

mut res := ''
for i in 0 .. 5 {
	println(i)
	res = py.exec(cmd: cmd)!
}
// res:=py.exec(cmd:cmd)!

person := json.decode(Person, res)!
println(person)
