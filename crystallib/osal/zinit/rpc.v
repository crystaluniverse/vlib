module zinit

import net.unix
import json
import freeflowuniverse.crystallib.ui.console

// these need to be all private (non pub)

pub struct Client {
	socket_path string = '/var/run/zinit.sock'
}

enum State {
	ok     @[json: 'ok']
	error  @[json: 'error']
}

struct ZinitResponse {
	state State
	body  string @[raw]
}

@[params]
struct ZinitClientArgs {
	socket_path string = '/var/run/zinit.sock'
}

pub fn new_rpc_client(args ZinitClientArgs) Client {
	return Client{
		socket_path: args.socket_path
	}
}

fn (z Client) connect() !&unix.StreamConn {
	mut s := unix.connect_stream(z.socket_path)!
	return s
}

fn close(sc &unix.StreamConn) {
	unix.shutdown(sc.sock.handle)
}

// get string from the zinit socket
fn (z Client) rpc(cmd string) !string {
	mut c := z.connect()!
	console.print_debug("zinit rpc: '${cmd}'")
	c.write_string(cmd + '\n')!
	mut res := []u8{len: 5000, cap: 5000}
	n := c.read(mut res)!
	close(c)
	return res[..n].bytestr()
}

fn (z Client) list() !map[string]string {
	response := z.rpc('list')!
	decoded_response := json.decode(ZinitResponse, response)!
	// println("")
	// println(decoded_response)
	// println("")
	if decoded_response.state == .error {
		$if debug {
			print_backtrace()
		}
		return error('zinit list failed: ${decoded_response.body}')
	}
	return json.decode(map[string]string, decoded_response.body)!
}

struct ServiceStatusRaw {
	after  map[string]string
	name   string
	pid    int
	state  string
	target string
}

//{"state":"ok","body":{"after":{"delay":"Success"},"name":"redis","pid":320996,"state":"Running","target":"Up"}}

// check if the service is known
fn (z Client) isloaded(name string) bool {
	// console.print_debug(" -- status rpc: '$name'")
	r := z.list() or { return false }
	if name !in r {
		return false
	}
	return true
}

fn (z Client) status(name string) !ServiceStatusRaw {
	// console.print_debug(" -- status rpc: '$name'")
	r := z.list()!
	if name !in r {
		$if debug {
			print_backtrace()
		}
		return error("cannot ask status over rpc, service with name:'${name}' not found in rpc daemon.\nFOUND:${r}")
	}

	response := z.rpc('status ${name}')!
	decoded_response := json.decode(ZinitResponse, response)!

	if decoded_response.state == .error {
		$if debug {
			print_backtrace()
		}
		return error('service ${name} status failed: ${decoded_response.body}')
	}

	return json.decode(ServiceStatusRaw, decoded_response.body)!
}

fn (z Client) start(name string) ! {
	response := z.rpc('start ${name}')!
	decoded_response := json.decode(ZinitResponse, response)!
	if decoded_response.state == .error {
		$if debug {
			print_backtrace()
		}
		return error('service ${name} start failed: ${decoded_response.body}')
	}
}

fn (z Client) stop(name string) ! {
	response := z.rpc('stop ${name}')!
	decoded_response := json.decode(ZinitResponse, response)!
	if decoded_response.state == .error {
		$if debug {
			print_backtrace()
		}
		return error('service ${name} stop failed: ${decoded_response.body}')
	}
}

fn (z Client) forget(name string) ! {
	response := z.rpc('forget ${name}')!
	decoded_response := json.decode(ZinitResponse, response)!
	if decoded_response.state == .error {
		$if debug {
			print_backtrace()
		}
		return error('service ${name} forget failed: ${decoded_response.body}')
	}
}

fn (z Client) monitor(name string) ! {
	response := z.rpc('monitor ${name}')!
	decoded_response := json.decode(ZinitResponse, response)!
	if decoded_response.state == .error {
		$if debug {
			print_backtrace()
		}
		return error('service ${name} monitor failed: ${decoded_response.body}')
	}
}

fn (z Client) kill(name string, signal string) ! {
	response := z.rpc('kill ${name} ${signal}')!
	decoded_response := json.decode(ZinitResponse, response)!
	if decoded_response.state == .error {
		$if debug {
			print_backtrace()
		}
		return error('service ${name} kill failed: ${decoded_response.body}')
	}
}

fn (z Client) shutdown() ! {
	response := z.rpc('shutdown')!
	decoded_response := json.decode(ZinitResponse, response)!
	if decoded_response.state == .error {
		$if debug {
			print_backtrace()
		}
		return error('zinit shutdown failed: ${decoded_response.body}')
	}
}

fn (z Client) reboot() ! {
	response := z.rpc('reboot')!
	decoded_response := json.decode(ZinitResponse, response)!
	if decoded_response.state == .error {
		$if debug {
			print_backtrace()
		}
		return error('zinit reboot failed: ${decoded_response.body}')
	}
}

fn (z Client) log(name string) !string {
	response := z.rpc('log ${name}')!
	decoded_response := json.decode(ZinitResponse, response)!
	if decoded_response.state == .error {
		$if debug {
			print_backtrace()
		}
		return error('zinit log failed: ${decoded_response.body}')
	}

	return decoded_response.body
}
