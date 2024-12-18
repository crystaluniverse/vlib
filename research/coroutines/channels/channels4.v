module main

import coroutines
import time
import os
// import net.http
import net
import io

// This file shows how a basic TCP echo server can be implemented using
// the net module. You can connect to the server by using netcat or telnet,
// in separate shells, for example:
// nc 127.0.0.1 12345
// or
// telnet 127.0.0.1 12345
fn server1() {
	// mut server := net.listen_tcp(.ip6, ':12345') or { panic(err) }
	mut server := net.listen_tcp(.ip, ':12345') or { panic(err) }
	laddr := server.addr() or { panic(err) }
	eprintln('Listen on ${laddr} ...')
	for {
		mut socket := server.accept() or { panic(err) }
		go handle_client1(mut socket)
	}
}

fn handle_client1(mut socket net.TcpConn) {
	println('handle client 1')
	defer {
		print('socket close')
		socket.close() or { panic(err) }
	}
	client_addr := socket.peer_addr() or { return }
	eprintln('> new client: ${client_addr}')
	mut reader := io.new_buffered_reader(reader: socket)
	defer {
		unsafe {
			reader.free()
		}
	}
	socket.write_string('server: hello\n') or { return }
	for {
		received_line := reader.read_line() or {
			print('error read line')
			return
		}
		if received_line == '' {
			print('empty line')
			return
		}
		println('client ${client_addr}: ${received_line}')
		socket.write_string('server: ${received_line}\n') or { return }
	}
}

fn server2() {
	mut server := net.listen_tcp(.ip6, ':12346') or { panic(err) }
	// mut server := net.listen_tcp(.unix, '/tmp/mysocket') or {panic(err)} //TODO: doesn't work
	laddr := server.addr() or { panic(err) }
	eprintln('Listen on ${laddr} ...')
	for {
		mut socket := server.accept() or { panic(err) }
		go handle_client2(mut socket)
	}
}

fn handle_client2(mut socket net.TcpConn) {
	defer {
		socket.close() or { panic(err) }
	}
	client_addr := socket.peer_addr() or { return }
	eprintln('> new client unix: ${client_addr}')
	mut reader := io.new_buffered_reader(reader: socket)
	defer {
		unsafe {
			reader.free()
		}
	}
	socket.write_string('server: hello\n') or { return }
	for {
		received_line := reader.read_line() or { return }
		if received_line == '' {
			return
		}
		println('client ${client_addr}: ${received_line}')
		socket.write_string('server: ${received_line}\n') or { return }
	}
}

fn foo1(ch chan string) {
	for {
		m := <-ch or { println('channel 1 has been closed') }
		println('1 ${m}')
		// coroutines.sleep(1 * time.second)
	}
}

fn foo2(ch chan string) {
	for {
		m := <-ch or { println('channel 1 has been closed') }
		println('2 ${m}')
		// coroutines.sleep(1 * time.second)
	}
}

fn monitor(ch chan string, counter int, mut t Test) {
	for {
		// println('2 ${m}')
		// coroutines.sleep(1 * time.second)
		t.mycounter += 1
		println('hello from monitor ${counter}')
		coroutines.sleep(100 * time.millisecond)
		println(t)
	}
}

pub struct Test {
pub mut:
	mycounter int
}

fn main() {
	ch1 := chan string{}
	ch2 := chan string{}

	go server1()
	go server2()
	go foo1(ch1)
	go foo2(ch2)

	mut t := Test{}
	mut c := 0
	for {
		c++
		go monitor(ch2, c, mut &t)
		#coroutines.sleep(1000 * time.millisecond)
	}

	$if is_coroutine ? {
		println('IS COROUTINE=true')
	} $else {
		println('IS COROUTINE=false')
	}
	mut counter := 0
	for {
		counter += 1
		println('hello from MAIN')
		ch1 <- '${counter}'
		ch2 <- '${counter}'
		coroutines.sleep(4000 * time.millisecond)
	}
	println('done')
}
