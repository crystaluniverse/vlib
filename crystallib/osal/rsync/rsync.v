module rsync

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal

@[params]
pub struct RsyncArgs {
pub mut:
	source         string
	dest           string
	ipaddr_src     string // e.g. root@192.168.5.5:33 (can be without root@ or :port)
	ipaddr_dst     string
	delete         bool     // do we want to delete the destination
	ignore         []string // arguments to ignore e.g. ['*.pyc','*.bak']
	ignore_default bool = true // if set will ignore a common set
	stdout         bool = true
	fast_rsync     bool
	sshkey 		   string
}

// flexible tool to sync files from to, does even support ssh .
// args: .
// ```
// 	source string
// 	dest string
// 	delete bool //do we want to delete the destination
//  ipaddr_src string //e.g. root@192.168.5.5:33 (can be without root@ or :port)
//  ipaddr_dst string //can only use src or dst, not both
// 	ignore []string //arguments to ignore
//  ignore_default bool = true //if set will ignore a common set
//  stdout bool = true
// ```
// .
// see https://github.com/freeflowuniverse/crystallib/blob/development/examples/pathlib.rsync/rsync_example.v
pub fn rsync(args_ RsyncArgs) ! {
	mut args := args_
	if args.ipaddr_src.len == 0 {
		pathlib.get(args.source)
	}
	args2 := pathlib.RsyncArgs{
		source:         args.source
		dest:           args.dest
		ipaddr_src:     args.ipaddr_src
		ipaddr_dst:     args.ipaddr_dst
		delete:         args.delete
		ignore:         args.ignore
		ignore_default: args.ignore_default
		fast_rsync:     args.fast_rsync
		sshkey:args.sshkey		
	}

	// TODO: is only for ssh right now, we prob need support for a real ssh server as well
	cmdoptions := pathlib.rsync_cmd_options(args2)!
	cmd := 'rsync ${cmdoptions}'
	$if debug {
		console.print_debug('rsync command (osal):\n${cmd}')
	}
	// console.print_debug(cmd)
	osal.exec(cmd: cmd, stdout: args_.stdout)!
}
