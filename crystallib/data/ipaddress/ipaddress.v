module ipaddress

import os
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console

pub struct IPNetwork {
	IPAddress
}

// specifies a range out of which e.g. ipaddresses can be chosen .
// note that checks need to be done to make sure that the IPAddresses are part of subnet as specified by parent object
pub struct IPNetworkRange {
	IPAddress
pub mut:
	from IPAddress
	to   IPAddress
}

pub struct IPAddress {
pub mut:
	addr        string // e.g. 192.168.6.6 or x:x:x:x:x:x:x:x
	mask        int    // e.g. 24, default not specified
	cat         IpAddressType = .ipv4
	description string
	port        int
}

pub enum IpAddressType {
	ipv4
	ipv6
	name
}

// TODO: implementation not correct !!!

// format: localhost:7777
// format: localhost:7777/24
// format: 192.168.6.6:7777
// format: 192.168.6.6
// format ipv6: [x:x:x:x:x:x:x:x]:p
// format ipv6: [x:x:x:x:x:x:x:x]:p/96
// format ipv6: x:x:x:x:x:x:x:x
// format ipv6: x:x:x:x.../96
pub fn new(addr_string string) !IPAddress {
	mut cat := IpAddressType.ipv4
	mut addr := addr_string
	mut port := ''
	mut mask := 0

	if addr_string.starts_with('localhost') {
		addr = addr_string.replace('localhost', '127.0.0.1')
	}

	if addr.contains('/') {
		splitted := addr.split(addr)
		if splitted.len == 2 {
			mask = splitted[1].int()
			addr = splitted[0]
		} else {
			return error('syntax error in ipaddr: ${addr}, should only have one /')
		}
	}

	// parse the ip addr
	if addr.count(':') > 4 && !addr.contains('[') {
		cat = IpAddressType.ipv6
		addr = addr.trim_space()
		port = '0'
	} else if addr.contains('[') && addr.count(']') == 1 {
		post := addr.all_after_last(']').trim_space()
		addr = addr.all_before_last(']').all_after_first('[').trim_space()
		cat = IpAddressType.ipv6
		port = '0'
		if post.len > 0 {
			if post.contains(':') {
				port = post.all_after(':').trim_space()
			} else {
				return error("syntax error in ip addr: '${addr}' should have : after ] if port")
			}
		}
	} else if ipv4_check(addr) {
		cat = IpAddressType.ipv4
		addr = addr.trim_space()
		port = '0'
		if addr.count(':') == 1 {
			port = addr.all_after_last(':').trim_space()
			addr = addr.all_before(':').trim_space()
		} else if addr.count(':') > 1 {
			return error('Invalid IP address string, port part \'${addr}\'')
		}
	} else if name_check(addr) {
		cat = IpAddressType.name
		addr = addr.trim_space()
		if addr.count(':') == 1 {
			port = addr.all_after_last(':').trim_space()
			addr = addr.all_before(':').trim_space()
		} else if addr.count(':') > 1 {
			return error('Invalid IP address string, port part \'${addr}\'')
		}
	} else {
		return error('Invalid IP address string \'${addr}\'')
	}

	mut ip := IPAddress{
		addr: addr.trim_space()
		port: port.int()
		cat:  cat
		mask: mask
	}

	// ip.check()!

	return ip
}

@[params]
pub struct PingArgs {
pub mut:
	retry   int
	timeout int
}

// PingArgs: retry & timeout
// retry default 1
// timeout default 1000 (msec)
pub fn (mut ipaddr IPAddress) ping(args_ PingArgs) bool {
	mut args := args_
	if args.retry == 0 {
		args.retry = 1
	}
	if args.timeout == 0 {
		args.timeout = 1000
	}

	mut timeout := int(args.timeout / 1000)
	if timeout < 1 {
		timeout = 1
	}

	mut cmd := ''
	if ipaddr.cat == IpAddressType.ipv4 {
		cmd = 'ping -c 1 -W ${args.timeout} ${ipaddr.addr}'
	} else {
		if osal.is_osx() {
			cmd = 'ping6 -c 1 -i ${timeout} ${ipaddr.addr}'
		} else {
			cmd = 'ping -6 -c 1 -W ${args.timeout} ${ipaddr.addr}'
		}
	}
	for _ in 0 .. args.retry {
		console.print_debug(cmd)
		res := os.execute(cmd)
		if res.exit_code > 0 {
			continue
		}
		return true
	}
	return false
}

// check if ipv4 address is properly formatted as aaa.bbb.ccc.ddd
pub fn ipv4_check(addr_ string) bool {
	mut addr := addr_
	if addr.contains(':') {
		addr = addr.all_before(':')
	}
	if addr.count('.') != 3 {
		return false
	}
	items := addr.split('.')
	for item in items {
		if !item.is_int() {
			return false
		}
		i := item.int()
		if i > 255 || i < 0 {
			return false
		}
	}
	if items.first().int() == 0 {
		return false
	}
	if items.last().int() == 0 {
		return false
	}
	return true
}

pub fn name_check(addr_ string) bool {
	mut addr := addr_.to_lower()
	if addr.contains(':') {
		addr = addr.all_before(':')
	}
	if addr.ends_with('.') || addr.starts_with('.') {
		return false
	}
	if addr.count('.') < 1 {
		return false
	}
	if addr.count('.') > 8 {
		return false
	}
	for u in addr {
		if u == 45 || u == 46 {
			continue
		} else if u > 47 && u < 58 { // see https://www.charset.org/utf-8
			continue
		} else if u > 96 && u < 123 {
			continue
		}
		return false
	}
	return true
}

pub fn (mut ipaddr IPAddress) toname() !string {
	if ipaddr.cat == IpAddressType.ipv4 {
		return ipaddr.addr.replace('.', '_')
	}
	if ipaddr.cat == IpAddressType.name {
		return ipaddr.addr.replace('.', '_')
	}
	return ipaddr.addr.replace(':', '_')
}

pub fn (mut ipaddr IPAddress) address() !string {
	if ipaddr.cat == IpAddressType.ipv4 {
		if ipaddr.port > 0 {
			if ipaddr.mask > 0 {
				return error('cannot have mask when port specified')
			}
			return '${ipaddr.addr}:${ipaddr.port}'
		} else {
			if ipaddr.mask > 0 {
				return '${ipaddr.addr}/${ipaddr.mask}'
			} else {
				return '${ipaddr.addr}'
			}
		}
	} else {
		if ipaddr.port > 0 {
			if ipaddr.mask > 0 {
				return error('cannot have mask when port specified')
			}
			return '[${ipaddr.addr}]:${ipaddr.port}'
		} else {
			if ipaddr.mask > 0 {
				return '${ipaddr.addr}/${ipaddr.mask}'
			} else {
				return '${ipaddr.addr}'
			}
		}
	}
}
