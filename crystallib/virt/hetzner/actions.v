module hetzner

import freeflowuniverse.crystallib.core.texttools
import time
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.builder

/////////////////////////// LIST

pub struct ServerInfo {
pub mut:
	server_ip       string
	server_ipv6_net string
	server_number   int
	server_name     string
	product         string
	dc              string
	traffic         string
	status          string
	cancelled       bool
	paid_until      string
	ip              []string
	subnet          []Subnet
}

pub struct ServerInfoDetailed {
	ServerInfo
pub mut:
	reset    bool
	rescue   bool
	vnc      bool
	windows  bool
	plesk    bool
	cpanel   bool
	wol      bool
	hot_swap bool
	// linked_storagebox    int
}

pub struct Subnet {
pub mut:
	ip   string
	mask string
}

pub fn (mut h HetznerManager) servers_list() ![]ServerInfo {
	mut conn := h.connection()!
	return conn.get_json_list_generic[ServerInfo](
		method:        .get
		prefix:        'server'
		list_dict_key: 'server'
	)!
}

// ///////////////////////////GETID

pub struct ServerGetArgs {
pub mut:
	id   int
	name string
}

pub fn (mut h HetznerManager) server_info_get(args_ ServerGetArgs) !ServerInfoDetailed {
	mut args := args_

	args.name = texttools.name_fix(args.name)

	l := h.servers_list()!

	mut res := []ServerInfo{}

	for item in l {
		if args.id > 0 && item.server_number != args.id {
			continue
		}
		server_name := texttools.name_fix(item.server_name)
		if args.name.len > 0 && server_name != args.name {
			continue
		}
		res << item
	}

	if res.len > 1 {
		return error("Found too many servers with: '${args}'")
	}
	if res.len == 0 {
		return error("couldn't find server with: '${args}'")
	}

	mut conn := h.connection()!
	return conn.get_json_generic[ServerInfoDetailed](
		method:        .get
		prefix:        'server/${res[0].server_number}'
		dict_key:      'server'
		cache_disable: true
	)!
}

// ///////////////////////////RESCUE

pub struct RescueInfo {
pub mut:
	server_ip       string
	server_ipv6_net string
	server_number   int
	os              string
	arch            int
	active          bool
	password        string
	authorized_key  []string
	host_key        []string
}

pub struct ServerRescueArgs {
pub mut:
	id              int
	name            string
	wait            bool = true
	crystal_install bool
	hero_install    bool
	sshkey_name     string
	reset           bool // ask to do reset/rescue even if its already in that state
}

// put server in rescue mode, if sshkey_name not specified then will use the first one in the list
pub fn (mut h HetznerManager) server_rescue(args ServerRescueArgs) !ServerInfoDetailed {
	mut serverinfo := h.server_info_get(id: args.id, name: args.name)!

	console.print_header('server ${serverinfo.server_name} goes into rescue mode')

	// only do it if its not in rescue yet
	if serverinfo.rescue == false || args.reset {
		mut key := h.keys_get()![0]
		if args.sshkey_name == '' {
			key = h.key_get(args.sshkey_name)!
		}

		mut conn := h.connection()!
		rescue := conn.post_json_generic[RescueInfo](
			prefix:     'boot/${serverinfo.server_number}/rescue'
			params:     {
				'os':             'linux'
				'authorized_key': key.fingerprint
			}
			dict_key:   'rescue'
			dataformat: .urlencoded
		)!

		console.print_debug('hetzner rescue\n${rescue}')

		h.server_reset(id: args.id, name: args.name, wait: args.wait)!
	}

	if args.wait {
		// now we should check if ssh is responding
		// next will do that check
		builder.executor_new(ipaddr: serverinfo.server_ip, checkconnect: 60)!
	}

	if args.crystal_install {
		mut b := builder.new()!
		mut n := b.node_new(ipaddr: serverinfo.server_ip)!
		n.crystal_install()!
	}

	if args.hero_install {
		mut b := builder.new()!
		mut n := b.node_new(ipaddr: serverinfo.server_ip)!
		n.hero_install()!
	}

	mut serverinfo2 := h.server_info_get(id: args.id, name: args.name)!

	return serverinfo2
}

pub fn (mut h HetznerManager) server_rescue_node(args ServerRescueArgs) !&builder.Node {
	mut serverinfo := h.server_rescue(args)!

	mut b := builder.new()!
	mut n := b.node_new(ipaddr: serverinfo.server_ip)!

	return n
}

// /////////////////////////////////////RESET

struct ResetInfo {
	server_ip        string
	server_ipv6_net  string
	server_number    int
	operating_status string
}

pub struct ServerRebootArgs {
pub mut:
	id   int
	name string
	wait bool = true
}

pub fn (mut h HetznerManager) server_reset(args ServerRebootArgs) !ResetInfo {
	mut serverinfo := h.server_info_get(id: args.id, name: args.name)!

	console.print_header('server ${serverinfo.server_name} goes for reset')

	mut serveractive := false
	if osal.ping(address: serverinfo.server_ip)! == .ok {
		serveractive = true
		console.print_debug('server ${serverinfo.server_name} is active')
	} else {
		console.print_debug('server ${serverinfo.server_name} is down')
	}

	mut conn := h.connection()!
	o := conn.post_json_generic[ResetInfo](
		prefix:     'reset/${serverinfo.server_number}'
		params:     {
			'type': 'hw'
		}
		dataformat: .urlencoded
		// dict_key:'reset'
	)!
	// now need to wait till it goes off
	if serveractive {
		for {
			console.print_debug('wait for server ${serverinfo.server_name} to go down.')
			if osal.ping(address: serverinfo.server_ip)! != .ok {
				console.print_debug('server ${serverinfo.server_name} is now down, now waitig for reboot.')
				break
			}
			time.sleep(1000 * time.millisecond)
		}
	}

	mut x := 0
	if args.wait {
		for {
			time.sleep(1000 * time.millisecond)
			console.print_debug('wait for ${serverinfo.server_name}')
			if osal.ping(address: serverinfo.server_ip)! == .ok {
				console.print_debug('ping ok')
				osal.tcp_port_test(address: serverinfo.server_ip, port: 22, timeout: 3000)
				console.print_debug('ssh tcp port ok')
				console.print_header('server is rebooted: ${serverinfo.server_name}')
				break
			}
			x += 1
			if x > 60 * 5 {
				// 5 min
				return error('Could not reboot server ${serverinfo.server_name} in 5 min')
			}
		}
	}

	return o
}

// /////////////////////////////////////BOOT

// struct BootRoot {
// 	boot Boot
// }

// struct Boot {
// 	rescue RescueInfo
// }

// pub fn (mut h HetznerManager) server_boot(id int) !RescueInfo {
// 	mut conn := h.connection()!
// 	boot := conn.get_json[BootRoot](prefix: 'boot/${id}')!
// 	return boot.boot.rescue
// }
