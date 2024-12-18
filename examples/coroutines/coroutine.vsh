#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import coroutines
import time

fn foo(mut t Test) {
	for {
		println('hello from foo() a=${t.a}')
		coroutines.sleep(1 * time.second)
	}
}

fn foo2(mut t Test) {
	for {
		println('hello from foo2() a=${t.a}')
		coroutines.sleep(1 * time.second)
		t.a += 1
	}
}

fn foo3(mut t Test) {
	for {
		println('hello from foo3() a=${t.a}')
		coroutines.sleep(1 * time.second)
	}
}

pub struct Test {
pub mut:
	a int
}

// coroutines.initialize()

mut t := Test{
	a: 100
}

go foo(mut &t)
go foo2(mut &t)
go foo3(mut &t)
for {
	println('hello from MAIN')
	coroutines.sleep(1 * time.second)
	// t.a+=10 //this works
}
println('done')
