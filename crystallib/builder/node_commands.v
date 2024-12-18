module builder

import freeflowuniverse.crystallib.core.texttools
import crypto.md5
import time
import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.osal

// check command exists on the platform, knows how to deal with different platforms
pub fn (mut node Node) cmd_exists(cmd string) bool {
	return node.exec_ok('which ${cmd}')
}

pub struct NodeExecCmd {
pub mut:
	name               string = 'default'
	cmd                string
	period             int // period in which we check when this was done last, if 0 then period is indefinite
	reset              bool = true // means do again or not
	remove_installer   bool = true // delete the installer
	description        string
	stdout             bool = true
	checkkey           string // if used will use this one in stead of hash of cmd, to check if was executed already
	tmpdir             string
	ignore_error_codes []int
}

// return the ipaddress as known on the public side
// is using resolver4.opendns.com
pub fn (mut node Node) ipaddr_pub_get() !string {
	if !node.done_exists('ipaddr') {
		cmd := 'dig @resolver4.opendns.com myip.opendns.com +short'
		res := node.exec(cmd: cmd, stdout: false)!
		node.done_set('ipaddr', res.trim('\n').trim(' \n'))!
	}
	mut ipaddr := node.done_get('ipaddr') or { return 'Error: ipaddr is none' }
	return ipaddr.trim('\n').trim(' \n')
}

// cmd: cmd to execute .
// period in sec, e.g. if 3600, means will only execute this if not done yet within the hour .
// .
// ARGS: .
//```
// struct NodeExecCmd{
// 	cmd string
// 	period int //period in which we check when this was done last, if 0 then period is indefinite
// 	reset bool = true
// 	description string
//	checkkey string //if used will use this one in stead of hash of cmd, to check if was executed already
// }
// ```
pub fn (mut node Node) exec_cmd(args_ NodeExecCmd) !string {
	// console.print_debug(args)
	mut args := args_
	mut cmd := args.cmd
	mut now_epoch := time.now().unix()
	mut now_str := now_epoch.str()
	if cmd.contains('\n') {
		cmd = texttools.dedent(cmd)
	}

	mut hhash := ''
	if args.checkkey.len > 0 {
		hhash = args.checkkey
	} else {
		hhash = md5.hexhash(cmd)
	}
	mut description := args.description
	if description == '' {
		description = cmd
		if description.contains('\n') {
			description = '\n${description}\n'
		}
	}
	if !args.reset && node.done_exists('exec_${hhash}') {
		if args.period == 0 {
			console.print_debug('   - exec cmd:${description} on ${node.name}: was already done, period indefinite.')
			return node.done_get('exec_${hhash}') or { '' }
		}
		nodedone := node.done_get_str('exec_${hhash}')
		splitted := nodedone.split('|')
		if splitted.len != 2 {
			panic("Cannot return from done on exec needs to have |, now \n'${nodedone}' ")
		}
		exec_last_time := splitted[0].int()
		lastoutput := splitted[1]
		assert exec_last_time > 10000
		// console.print_debug(args)
		// console.print_debug("   - check exec cmd:$cmd on $node.name: time:$exec_last_time")
		if exec_last_time > now_epoch - args.period {
			hours := args.period / 3600
			console.print_header('exec cmd:${description} on ${node.name}: was already done, period ${hours} h')
			return lastoutput
		}
	}

	if args.tmpdir.len == 0 {
		if 'TMPDIR' !in node.environment {
			args.tmpdir = '/tmp'
		} else {
			args.tmpdir = node.environment['TMPDIR']
		}
	}
	now := ourtime.now()
	r_path := '${args.tmpdir}/installer_${args.name}_${now.key()}.sh'

	node.file_write(r_path, cmd)!
	cmd = "mkdir -p ${args.tmpdir} && cd ${args.tmpdir} && export TMPDIR='${args.tmpdir}' && bash ${r_path}"

	if args.remove_installer {
		cmd += ' && rm -f ${r_path}'
	}
	$if debug {
		console.print_header('exec ${r_path} on ${node.name}')
	}
	res := node.exec(cmd: cmd, stdout: args.stdout) or {
		return error('cmd:\n${args.cmd}\n${err.msg()}')
	}

	node.done_set('exec_${hhash}', '${now_str}|${res}')!
	return res
}

// check if we can execute and there is not errorcode
pub fn (mut node Node) exec_ok(cmd string) bool {
	// TODO: need to put in support for multiline text files
	if cmd.contains('\n') {
		panic('cannot have \\n in cmd. ${cmd}, use exec function instead')
	}
	node.exec_silent(cmd) or {
		// see if it executes ok, if cmd not found is false
		return false
	}
	// console.print_debug(e)
	return true
}

fn (mut node Node) platform_load() ! {
	console.print_header('platform load ${node.name}')
	cmd := '
    if [[ "\$OSTYPE" == "darwin"* ]]; then
        export OSNAME="darwin"
    elif [ -e /etc/os-release ]; then
        # Read the ID field from the /etc/os-release file
        export OSNAME=$(grep \'^ID=\' /etc/os-release | cut -d= -f2)
        if [ "\${os_id,,}" == "ubuntu" ]; then
            export OSNAME="ubuntu"          
        fi
        if [ "\${OSNAME}" == "archarm" ]; then
            export OSNAME="arch"          
        fi        
    else
        echo "Unable to determine the operating system."
        exit 1        
    fi
	export HOSTNAME=\$(hostname)
	export UNAME=\$(uname -m)
	echo ***\${OSNAME}:\${UNAME}:\${HOSTNAME}

	'
	out := node.exec_cmd(cmd: cmd, name: 'platform_load', stdout: false)!

	out2 := out.split_into_lines().map(if it.starts_with('***') { it.trim_left('*') } else { '' }).first()
	if out2.count(':') != 2 {
		panic('platform loader bug')
	}
	splitted := out2.split(':').map(it.trim_space())
	osname := splitted[0]
	cputype := splitted[1]
	node.hostname = splitted[2]

	if cputype == 'x86_64' {
		node.cputype = CPUType.intel
	} else if cputype == 'arm64' || cputype == 'aarch64' {
		node.cputype = CPUType.arm
	} else {
		return error("did not find cpu type, implement more types e.g. 32 bit. found: '${cputype}'")
	}

	if osname == 'arch' {
		node.platform = PlatformType.arch
	} else if osname == 'ubuntu' || osname == 'debian' {
		node.platform = PlatformType.ubuntu
	} else if osname == 'darwin' {
		node.platform = PlatformType.osx
	} else if osname == 'alpine' {
		node.platform = PlatformType.alpine
	} else {
		console.print_stderr(osname)
		panic('only ubuntu, arch and osx supported for now')
	}
	console.print_debug('platform loaded')
}

pub fn (mut node Node) package_refresh() ! {
	if node.platform == PlatformType.ubuntu {
		console.print_header('package refresh')
		node.exec(cmd: 'apt-get update', stdout: false) or {
			return error('could not update packages list\nerror:\n${err}')
		}
	}
}

pub fn (mut node Node) package_install(package Package) ! {
	name := package.name
	if node.platform == PlatformType.osx {
		node.exec(cmd: 'brew install ${name}') or {
			return error('could not install package:${package.name}\nerror:\n${err}')
		}
	} else if node.platform == PlatformType.ubuntu {
		node.exec(cmd: 'apt install -y ${name}') or {
			return error('could not install package:${package.name}\nerror:\n${err}')
		}
	} else if node.platform == PlatformType.alpine {
		node.exec(cmd: 'apk install ${name}') or {
			return error('could not install package:${package.name}\nerror:\n${err}')
		}
	} else if node.platform == PlatformType.alpine {
		node.exec(cmd: 'pacman -Su ${name}') or {
			return error('could not install package:${package.name}\nerror:\n${err}')
		}
	} else {
		panic('only ubuntu, alpine,arch and osx supported for now')
	}
}
