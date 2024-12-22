module builder

import os
import rand
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.rsync
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.ipaddress
import freeflowuniverse.crystallib.ui.console
import time
import crypto.md5

@[heap]
pub struct ExecutorSSH {
pub mut:
	ipaddr       ipaddress.IPAddress
	sshkey       string
	user         string = 'root' // default will be root
	initialized  bool
	retry        int  = 1 // nr of times something will be retried before failing, need to check also what error is, only things which should be retried need to be done
	debug        bool = true
	checkconnect int // if set then will test the ssh connection for that timeout
}

fn (mut executor ExecutorSSH) init() ! {
	if !executor.initialized {
		// if executor.ipaddr.port == 0 {
		// 	return error('port cannot be 0.\n${executor}')
		// }
		// TODO: need to call code from SSHAGENT do not reimplement here, not nicely done
		// os.execute('pgrep -x ssh-agent || eval `ssh-agent -s`')

		// if executor.sshkey != '' {
		// 	osal.exec(cmd: 'ssh-add ${executor.sshkey}')!
		// }
		mut addr := executor.ipaddr.addr
		if addr == '' {
			addr = 'localhost'
		}
		if executor.ipaddr.port == 0 {
			executor.ipaddr.port = 22
		}

		if executor.sshkey.len > 0 {
			if !os.exists(executor.sshkey) {
				mypath := '/tmp/ssh_${md5.hexhash(executor.sshkey)}'
				os.write_file(mypath, executor.sshkey)!
				executor.sshkey = mypath
			}
		}

		// TODO: doesn't work with ipv6 after working with ipv4, need better check too, because this slows everything down
		// cmd := "sh -c 'ssh-keyscan -H ${executor.ipaddr.addr} -p ${executor.ipaddr.port} -t ecdsa-sha2-nistp256 2>/dev/null >> ~/.ssh/known_hosts'"
		// osal.execute_silent(cmd) or { return error('cannot add the ssh keys to known hosts') }

		if executor.checkconnect > 0 {
			end := time.now().unix() + executor.checkconnect
			mut now := i64(0)
			for {
				if now > end {
					break
				}
				if executor.ping()! {
					executor.initialized = true
					return
				}
				time.sleep(time.second)
				now = time.now().unix()
			}
			return error("couldn't establish the ssh connection to ${executor}")
		}
		executor.initialized = true
	}
}

pub fn (mut executor ExecutorSSH) debug_on() {
	executor.debug = true
}

pub fn (mut executor ExecutorSSH) debug_off() {
	executor.debug = false
}

pub fn (mut executor ExecutorSSH) exec(args_ ExecArgs) !string {
	mut args := args_
	if executor.debug {
		console.print_debug('execute ${executor.ipaddr.addr}: ${args.cmd}')
	}
	mut port := ''
	if executor.ipaddr.port > 10 {
		port = '-p ${executor.ipaddr.port}'
	}
	mut sshkey := ''
	if os.exists(executor.sshkey) {
		sshkey = '-i ${executor.sshkey} '
	}

	args.cmd = 'ssh -o StrictHostKeyChecking=no ${sshkey}${executor.user}@${executor.ipaddr.addr} ${port} "${args.cmd}"'
	res := osal.exec(cmd: args.cmd, stdout: args.stdout, debug: executor.debug)!
	return res.output
}

// test if ssh connection works
pub fn (mut executor ExecutorSSH) ping() !bool {
	mut sshkey := ''
	if os.exists(executor.sshkey) {
		sshkey = '-i ${executor.sshkey} '
	}
	mut port := ''
	if executor.ipaddr.port > 10 {
		port = '-p ${executor.ipaddr.port}'
	}
	cmd := 'ssh -o StrictHostKeyChecking=no -q -o BatchMode=yes ${sshkey} ${executor.user}@${executor.ipaddr.addr} ${port} exit'
	print(cmd)
	res := os.execute(cmd)
	if res.exit_code == 0 {
		println('-> ssh ok')
		return true
	}
	println('-> ssh failed')
	return false
}

pub fn (mut executor ExecutorSSH) exec_interactive(args_ ExecArgs) ! {
	mut args := args_
	mut port := ''
	if executor.ipaddr.port > 10 {
		port = '-p ${executor.ipaddr.port}'
	}
	mut sshkey := ''
	if os.exists(executor.sshkey) {
		sshkey = '-i ${executor.sshkey} '
	}
	args.cmd = 'ssh -tt -o StrictHostKeyChecking=no ${sshkey}${executor.user}@${executor.ipaddr.addr} ${port} "${args.cmd}"'
	osal.execute_interactive(args.cmd)!
}

pub fn (mut executor ExecutorSSH) file_write(path string, text string) ! {
	if executor.debug {
		console.print_debug('${executor.ipaddr.addr} file write: ${path}')
	}
	local_path := '/tmp/${rand.uuid_v4()}'
	os.write_file(local_path, text)!
	executor.upload(source: local_path, dest: path, stdout: false)!
	os.rm(local_path)!
}

pub fn (mut executor ExecutorSSH) file_read(path string) !string {
	if executor.debug {
		console.print_debug('${executor.ipaddr.addr} file read: ${path}')
	}
	local_path := '/tmp/${rand.uuid_v4()}'
	executor.download(source: path, dest: local_path)!
	r := os.read_file(local_path)!
	os.rm(local_path) or { panic(err) }
	return r
}

pub fn (mut executor ExecutorSSH) file_exists(path string) bool {
	if executor.debug {
		console.print_debug('${executor.ipaddr.addr} file exists: ${path}')
	}
	output := executor.exec(cmd: 'test -f ${path} && echo found || echo not found', stdout: false) or {
		return false
	}
	if output == 'found' {
		return true
	}
	return false
}

// carefull removes everything
pub fn (mut executor ExecutorSSH) delete(path string) ! {
	if executor.debug {
		console.print_debug('${executor.ipaddr.addr} file delete: ${path}')
	}
	executor.exec(cmd: 'rm -rf ${path}', stdout: false) or { panic(err) }
}

// upload from local FS to executor FS
pub fn (mut executor ExecutorSSH) download(args SyncArgs) ! {
	mut addr := '${executor.user}@${executor.ipaddr.addr}:${executor.ipaddr.port}'
	if executor.ipaddr.cat == .ipv6 {
		addr = '\'${executor.user}@[${executor.ipaddr.addr}]\':${executor.ipaddr.port}'
	}
	mut rsargs := rsync.RsyncArgs{
		source:         args.source
		dest:           args.dest
		delete:         args.delete
		ipaddr_src:     addr
		ignore:         args.ignore
		ignore_default: args.ignore_default
		stdout:         args.stdout
		sshkey:         executor.sshkey
	}
	rsync.rsync(rsargs)!
}

// download from executor FS to local FS
pub fn (mut executor ExecutorSSH) upload(args SyncArgs) ! {
	mut p := pathlib.get(args.source)
	if !p.exists() {
		return error('Cannot upload ${args}')
	}

	mut psize := p.size_kb()!

	// source         string
	// dest           string
	// delete         bool     // do we want to delete the destination
	// ipaddr         string   // e.g. root@192.168.5.5:33 (can be without root@ or :port)
	// ignore         []string // arguments to ignore e.g. ['*.pyc','*.bak']
	// ignore_default bool = true // if set will ignore a common set
	// stdout         bool = true
	// fast_rsync     bool = true	
	if args.ignore.len == 0 && psize < 100 {
		mut addr2 := '${executor.user}@${executor.ipaddr.addr}:${args.dest}'
		if executor.ipaddr.cat == .ipv6 {
			addr2 = '\'${executor.user}@[${executor.ipaddr.addr}]\':${args.dest}'
		}
		cmd := "scp -o \"StrictHostKeyChecking=no\" -P ${executor.ipaddr.port} ${args.source} ${addr2}"
		// console.print_debug(cmd)
		res := os.execute(cmd)
		if res.exit_code > 0 {
			return error('cannot upload over ssh: ${cmd}')
		}
		return
	}

	mut addr := '${executor.user}@${executor.ipaddr.addr}:${executor.ipaddr.port}'
	if executor.ipaddr.cat == .ipv6 {
		addr = '\'${executor.user}@[${executor.ipaddr.addr}]\':${executor.ipaddr.port}'
	}

	mut rsargs := rsync.RsyncArgs{
		source:         args.source
		dest:           args.dest
		delete:         args.delete
		ipaddr_dst:     addr
		ignore:         args.ignore
		ignore_default: args.ignore_default
		stdout:         args.stdout
		fast_rsync:     args.fast_rsync
		sshkey:         executor.sshkey
	}
	rsync.rsync(rsargs)!
}

// get environment variables from the executor
pub fn (mut executor ExecutorSSH) environ_get() !map[string]string {
	env := executor.exec(cmd: 'env', stdout: false) or { return error('can not get environment') }
	// if executor.debug {
	// 	console.print_header(' ${executor.ipaddr.addr} env get')
	// }

	mut res := map[string]string{}
	if env.contains('\n') {
		for line in env.split('\n') {
			if line.contains('=') {
				splitted := line.split('=')
				key := splitted[0].trim(' ')
				val := splitted[1].trim(' ')
				res[key] = val
			}
		}
	}
	return res
}

/*
Executor info or meta data
accessing type Executor won't allow to access the
fields of the struct, so this is workaround
*/
pub fn (mut executor ExecutorSSH) info() map[string]string {
	return {
		'category':  'ssh'
		'sshkey':    executor.sshkey
		'user':      executor.user
		'ipaddress': executor.ipaddr.addr
		'port':      '${executor.ipaddr.port}'
	}
}

// ssh shell on the node default ssh port, or any custom port that may be
// forwarding ssh traffic to certain container

pub fn (mut executor ExecutorSSH) shell(cmd string) ! {
	if cmd.len > 0 {
		panic('TODO IMPLEMENT SHELL EXEC OVER SSH')
	}
	os.execvp('ssh', ['-o StrictHostKeyChecking=no', '${executor.user}@${executor.ipaddr.addr}',
		'-p ${executor.ipaddr.port}'])!
}

pub fn (mut executor ExecutorSSH) list(path string) ![]string {
	if !executor.dir_exists(path) {
		panic('Dir Not found')
	}
	mut res := []string{}
	output := executor.exec(cmd: 'ls ${path}', stdout: false)!
	for line in output.split('\n') {
		res << line
	}
	return res
}

pub fn (mut executor ExecutorSSH) dir_exists(path string) bool {
	output := executor.exec(cmd: 'test -d ${path} && echo found || echo not found', stdout: false) or {
		return false
	}
	if output.trim_space() == 'found' {
		return true
	}
	return false
}
