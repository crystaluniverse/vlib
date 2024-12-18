#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.data.encoderhero
import freeflowuniverse.crystallib.core.base

// this is docu at top
@[name: 'teststruct ']
@[params]
pub struct TestStruct {
	// this is docu at mid
pub mut:
	id      int @[hi]
	descr   string
	secret  string @[secret]
	number  int = 1    @[max: 10; min: 1]
	yesno   bool
	liststr []string
	listint []int
	ss      SubStruct
	ss2     []SubStruct
}

pub struct SubStruct {
pub mut:
	color string
	size  int
}

fn (self TestStruct) heroscript() !string {
	mut out := ''
	mut p := encoderhero.encode[TestStruct](self)!
	// out += "!!hr.teststruct_define " + p.heroscript() + "\n"
	// p = paramsparser.encode[SubStruct](self.ss)!
	// p.set("teststruct_id",self.id.str())
	// out += "!!hr.substruct_define " + p.heroscript() + "\n"
	// for ss2 in self.ss2{
	// 	p = paramsparser.encode[SubStruct](ss2)!
	// 	p.set("teststruct_id",self.id.str())
	// 	out += "!!hr.substruct_item_define " + p.heroscript() + "\n"
	// }
	return p
}

mut t := TestStruct{
	id:      100
	descr:   '
		test
		muliline
		s
		test
		muliline
		test
		muliline				
		'
	number:  2
	yesno:   true
	liststr: ['one', 'two+two']
	listint: [1, 2]
	ss:      SubStruct{
		color: 'red'
		size:  10
	}
}
t.ss2 << SubStruct{
	color: 'red1'
	size:  11
}
t.ss2 << SubStruct{
	color: 'red2'
	size:  12
}

println(t.heroscript()!)

// t2:=p.decode[TestStruct]()!
// println(t2)
