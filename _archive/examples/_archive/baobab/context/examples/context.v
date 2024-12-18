module main

import time
import freeflowuniverse.crystallib.baobab.context

fn do2() ! {
	for i in 10 .. 1000 {
		// println("lock")
		// lock contexts {
		mut c2 := context.get(cid: 'mycid')!
		c2.end.now()
		println(i)
		// }
		// println("lock free")
		time.sleep(time.Duration(time.second))
	}
}

fn do() ! {
	mut c := context.get(cid: 'mycid', redis: 'localhost:7777')!
	mut c2 := context.get(cid: 'mycid')!
	c2.end.now()
	println(c)
	mut c3 := context.get(cid: 'mycid', redis: 'localhost:7777')!
	println(c)
	spawn do2()
	for i in 0 .. 100 {
		// println("rlock")
		// rlock contexts {
		mut c4 := context.get(cid: 'mycid')!
		println(c4)
		// }
		// println("rlock free")
		time.sleep(time.Duration(time.second))
	}
}

fn main() {
	do() or { panic(err) }
}
