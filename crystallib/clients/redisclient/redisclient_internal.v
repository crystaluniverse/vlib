module redisclient
import os
import net
import freeflowuniverse.crystallib.data.resp
import time
import net.unix


pub struct SetOpts {
	ex       int = -4
	px       int = -4
	nx       bool
	xx       bool
	keep_ttl bool
}

pub enum KeyType {
	t_none
	t_string
	t_list
	t_set
	t_zset
	t_hash
	t_stream
	t_unknown
}


fn (mut r Redis) socket_connect() ! {
	// print_backtrace()
	addr := os.expand_tilde_to_home(r.addr)
	// console.print_debug(' - REDIS CONNECT: ${addr}')
	if !addr.contains(':') {
		unix_socket := unix.connect_stream(addr)!
		tcp_socket := net.tcp_socket_from_handle_raw(unix_socket.sock.Socket.handle)
		tcp_conn := net.TcpConn{
			sock: tcp_socket
			handle: unix_socket.sock.Socket.handle
		}
		r.socket = tcp_conn
	} else {
		r.socket = net.dial_tcp(addr)!
	}

	r.socket.set_blocking(true)!
	r.socket.set_read_timeout(1 * time.second)
	// console.print_debug("---OK")
}

fn (mut r Redis) socket_check() ! {
	r.socket.peer_addr() or {
		// console.print_debug(' - re-connect socket for redis')
		r.socket_connect()!
	}
}

pub fn (mut r Redis) read_line() !string {
	return r.socket.read_line().trim_right('\r\n')
}

// write *all the data* into the socket
// This function loops, till *everything is written*
// (some of the socket write ops could be partial)
fn (mut r Redis) write(data []u8) ! {
	r.socket_check()!
	mut remaining := data.len
	for remaining > 0 {
		// zdbdata[data.len - remaining..].bytestr())
		written_bytes := r.socket.write(data[data.len - remaining..])!
		remaining -= written_bytes
	}
}

fn (mut r Redis) read(size int) ![]u8 {
	r.socket_check() or {}
	mut buf := []u8{len: size}
	mut remaining := size
	for remaining > 0 {
		read_bytes := r.socket.read(mut buf[buf.len - remaining..])!
		remaining -= read_bytes
	}
	return buf
}

pub fn (mut r Redis) disconnect() {
	r.socket.close() or {}
}

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

// TODO: need to implement a way how to use multiple connections at once

const cr_lf_bytes = [u8(`\r`), `\n`]

fn (mut r Redis) write_line(data []u8) ! {
	r.write(data)!
	r.write(redisclient.cr_lf_bytes)!
}

// write resp value to the redis channel
pub fn (mut r Redis) write_rval(val resp.RValue) ! {
	r.write(val.encode())!
}

// write list of strings to redis challen
fn (mut r Redis) write_cmd(item string) ! {
	a := resp.r_bytestring(item.bytes())
	r.write_rval(a)!
}

// write list of strings to redis challen
fn (mut r Redis) write_cmds(items []string) ! {
	// if items.len==1{
	// 	a := resp.r_bytestring(items[0].bytes())
	// 	r.write_rval(a)!
	// }{
	a := resp.r_list_bstring(items)
	r.write_rval(a)!
	// }	
}
