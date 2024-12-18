module main

import coroutines
import time
import os
import net.http
import net
import os.notify

fn server() {
	$if !linux {
		eprintln('This example only works on Linux')
		exit(1)
	}

	// create TCP listener
	mut listener := net.listen_tcp(.ip, 'localhost:9001') or { panic(err) }
	defer {
		listener.close() or {}
	}
	addr := listener.addr() or { panic(err) }
	eprintln('Listening on ${addr}')
	eprintln('Type `stop` to stop the server')

	// create file descriptor notifier
	mut notifier := notify.new() or { panic(err) }
	defer {
		notifier.close() or {}
	}
	notifier.add(os.stdin().fd, .read) or { panic(err) }
	notifier.add(listener.sock.handle, .read) or { panic(err) }

	for {
		for event in notifier.wait(time.infinite) {
			println(event)
			match event.fd {
				listener.sock.handle {
					// someone is trying to connect
					eprint('trying to connect.. ')
					if conn := listener.accept() {
						notifier.add(conn.sock.handle, .read | .peer_hangup) or {
							eprintln('error adding to notifier: ${err}')
							return
						}
						eprintln('connected')
					} else {
						eprintln('unable to accept: ${err}')
					}
				}
				0 {
					// stdin
					s, _ := os.fd_read(event.fd, 10)
					if s == 'stop\n' {
						eprintln('stopping')
						return
					}
				}
				else {
					// remote connection
					if event.kind.has(.peer_hangup) {
						notifier.remove(event.fd) or {
							eprintln('error removing from notifier: ${err}')
							return
						}
						eprintln('remote disconnected')
					} else {
						s, _ := os.fd_read(event.fd, 10)
						os.fd_write(event.fd, s)
					}
				}
			}
		}
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

fn main() {
	ch1 := chan string{}
	ch2 := chan string{}

	go server()
	go foo1(ch1)
	go foo2(ch2)
	go monitor(ch2, mycounter)

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
		coroutines.sleep(1000 * time.millisecond)
	}
	println('done')
}
