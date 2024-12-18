module main

import coroutines
import time

pub struct TestStruct {
pub mut:
	mycounter int
}

fn monitor(ch chan string, counter int, mut t &TestStruct) {
	t.mycounter += 1
	println('hello from monitor ${counter}')
	coroutines.sleep(5000 * time.second)
	println(t)
}

fn main() {
	ch1 := chan string{}
	ch2 := chan string{}

	mut t := TestStruct{}
	mut c := 0
	for i in 0 .. 1000 {
		c++
		go monitor(ch2, c, mut &t)
	}

	coroutines.sleep(4000 * time.second)

	// mut counter := 0
	// for {
	// 	counter += 1
	// 	println('hello from MAIN')
	// 	ch1 <- '${counter}'
	// 	ch2 <- '${counter}'
	// 	coroutines.sleep(4000 * time.millisecond)
	// }
	// println('done')
}
