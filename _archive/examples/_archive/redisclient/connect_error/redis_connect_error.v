module main

import net
import time

fn do() ! {
	for i in 0 .. 10000 {
		println(i)
		// time.sleep(1 * time.millisecond)
		mut socket := net.dial_tcp('127.0.0.1:6379')!
	}
}

fn main() {
	do() or { panic(err) }
}
