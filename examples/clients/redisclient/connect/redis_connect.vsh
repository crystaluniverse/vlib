#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.redisclient
import time

fn conn_for_thread(c int) {
	println('thread ${c}')
	// time.sleep(100 * time.millisecond)
	mut redis := redisclient.core_get() or { panic(err) }
	println('ok ${c}')
	redis.set('test', 'some data') or { panic('set ' + err.str() + '\n' + c.str()) }
	redis.get('test') or { panic('get ' + err.str() + '\n' + c.str()) }
}

fn conn2(c int) !bool {
	// mut socket := net.dial_tcp("localhost:6379")?
	// mut socket := net.dial_tcp("/tmp/redis.sock")?

	// socket.set_blocking(true)  or {panic(err)}
	// socket.set_read_timeout(10 * time.second)
	// socket.peer_addr()  or {panic(err)}

	// ONCE THIS WORKS, WE SHOULD TEST NEXT AS well, ENABLE REDIS CLIENT ABOVE

	mut redis := redisclient.core_get()!
	redis.set('test', 'some data') or { panic('set' + err.str() + '\n' + c.str()) }
	r := redis.get('test')!
	if r != 'some data' {
		panic('get error different result.' + '\n' + c.str())
	}
	return true
}

fn redistest() ! {
	mut threads := []thread{}

	for c in 0 .. 200 {
		// even if going slower does not work?
		time.sleep(1 * time.millisecond)
		threads << spawn conn_for_thread(c)
	}
	threads.wait()

	println('TEST OK THREADS')
}

fn redistest_nothreads() ? {
	for c in 0 .. 10000 {
		println(c)
		// time.sleep(1 * time.millisecond)
		// test with conn as well
		res := conn2(c) or { false }
		if res {
			continue
		}
		println('connect failed ${c}')
	}

	println('TEST NO THREADS OK')
}

redistest() or { panic(err) }
// redistest_nothreads() or { panic(err) }
