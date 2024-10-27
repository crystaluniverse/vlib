module zinit

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.ourtime
import time
import json

@[params]
pub struct ZinitConfig {
	path string = '/etc/zinit'
	pathcmds string = '/etc/zinit/cmds'
}

pub struct ZinitStateless {
pub mut:
	client    Client
	path      pathlib.Path
	pathcmds  pathlib.Path
}

pub fn new_stateless(z ZinitConfig) !ZinitStateless {
	return ZinitStateless{
		client: new_rpc_client()
		path: pathlib.get_dir(path: '/etc/zinit', create: true)!
		pathcmds: pathlib.get_dir(path: '/etc/zinit/cmds', create: true)!
	}
}	

// will delete the process if it exists while starting
pub fn (mut zinit ZinitStateless) new(args_ ZProcessNewArgs) !ZProcess {
	console.print_header(' zinit process new')
	mut args := args_

	if args.cmd.len == 0 {
		$if debug {
			print_backtrace()
		}
		return error('cmd cannot be empty for ${args} in zinit.')
	}

	if zinit.exists(args.name)! {
		zinit.delete(args.name)!
	}

	mut zp := ZProcess{
		name: args.name
		cmd: args.cmd
		cmd_test: args.cmd_test
		cmd_stop: args.cmd_stop
		env: args.env.move()
		after:args.after
		start:args.start
		restart:args.restart
		oneshot:args.oneshot
		workdir: args.workdir
	}

	zinit.cmd_write(args.name,args.cmd,"_start",{},args.workdir)!
	zinit.cmd_write(args.name,args.cmd_test,"_test",{},args.workdir)!
	zinit.cmd_write(args.name,args.cmd_stop,"_stop",{},args.workdir)!

    mut json_path := zinit.pathcmds.file_get_new('${args.name}.json')!
    json_content := json.encode(args)
    json_path.write(json_content)!	

	mut pathyaml := zinit.path.file_get_new(zp.name + '.yaml')!
	// console.print_debug('debug zprocess path yaml: ${pathyaml}')
	pathyaml.write(zp.config_content()!)!
	
	zinit.client.monitor(args.name)!
	assert zinit.exists(args.name)!
	
	if args.start {
		zinit.client.start(args.name)!
	}

	return zp
}

fn (mut zinit ZinitStateless) cmd_write(name string,cmd string, cat string, env map[string]string,workdir string) !string {
	if cmd.trim_space()==""{
		return""
	}
	mut zinitobj := new()!
	mut pathcmd := zinitobj.pathcmds.file_get_new("${name}${cat}.sh")!
	mut cmd_out:="#!/bin/bash\nset -e\n\n"
	
	if cat=="_start"{
		cmd_out += 'echo === START ======== ${ourtime.now().str()} === \n'
	}
	for key,val in env{
		cmd_out+="${key}=${val}\n"
	}

	if workdir.trim_space()!=""{
		cmd_out+="cd ${ workdir.trim_space()}\n"
	}
	
	cmd_out+=texttools.dedent(cmd) + '\n'
	pathcmd.write(cmd_out)!
	pathcmd.chmod(0x770)!
	return '/bin/bash -c ${pathcmd.path}'
}

pub fn (zinit ZinitStateless) exists(name string) !bool {
	return name in zinit.client.list()!
}

pub fn (mut zinit ZinitStateless) stop(name string) ! {
	zinit.client.stop(name)!
}

pub fn (mut zinit ZinitStateless) start(name string) ! {
	zinit.client.start(name)!
}

pub fn (mut zinit ZinitStateless) running(name string) !bool {
	if !zinit.exists(name)! { return false }
	return zinit.client.status(name)!.state == 'Running'
}

pub fn (mut zinit ZinitStateless) delete(name string) ! {
	zinit.client.stop(name)!
	time.sleep(1000000)
	zinit.client.forget(name)!
}

pub fn (mut self ZinitStateless) names() ![]string {
	return self.client.list()!.keys()
}