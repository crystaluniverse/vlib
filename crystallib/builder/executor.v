module builder

import freeflowuniverse.crystallib.data.ipaddress

type Executor = ExecutorLocal | ExecutorSSH

pub struct ExecutorNewArguments {
pub mut:
	local        bool // if this set then will always be the local machine
	ipaddr       string
	user         string = 'root'
	debug        bool
	checkconnect int
}

// create new executor (is way how to execute in std way onto a local or remote machine)
// pub struct ExecutorNewArguments {
// 	local  false //if this set then will always be the local machine
// 	ipaddr string
// 	user   string = "root"
// 	debug  bool
// 	}
//- format ipaddr: 192.168.6.6:7777
//- format ipaddr: 192.168.6.6
//- format ipadd6: [666:555:555:...]
//- format ipaddr: any ipv6 addr
//- if ipaddr is empty or starts with localhost or 127.0.0.1 -> will be the ExecutorLocal
pub fn executor_new(args_ ExecutorNewArguments) !Executor {
	mut args := args_
	hasport := args.ipaddr.contains(':')
	if !hasport {
		args.ipaddr = args.ipaddr + ':22'
	}
	if args.ipaddr == ''
		|| (args.ipaddr.starts_with('localhost') && hasport == false)
		|| (args.ipaddr.starts_with('127.0.0.1') && hasport == false) {
		return ExecutorLocal{
			debug: args.debug
		}
	} else {
		ipaddr := ipaddress.new(args.ipaddr) or {
			return error('can not initialize ip address.\n ${err}')
		}
		mut e := ExecutorSSH{
			ipaddr:       ipaddr
			user:         args.user
			debug:        args.debug
			checkconnect: args.checkconnect
		}
		e.init()!
		return e
	}
}

@[params]
pub struct ExecArgs {
pub mut:
	cmd    string
	stdout bool = true
}
