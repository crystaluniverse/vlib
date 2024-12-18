module herocontainers

import freeflowuniverse.crystallib.osal
// import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.installers.lang.crystallib
import freeflowuniverse.crystallib.core.pathlib
import os
import json

// is builderah containers

// pub enum ContainerStatus {
// 	up
// 	down
// 	restarting
// 	paused
// 	dead
// 	created
// }

// need to fill in what is relevant
@[heap]
pub struct Builder {
pub mut:
	id            string
	builder       bool
	imageid       string
	imagename     string
	containername string
	engine        &CEngine @[skip; str: skip]
	// hero_in_container bool //once the hero has been installed this is on, does it once per session
	// created         time.Time
	// ssh_enabled     bool // if yes make sure ssh is enabled to the container
	// ipaddr          IPAddress
	// forwarded_ports []string
	// mounts          []ContainerVolume
	// ssh_port        int // ssh port on node that is used to get ssh
	// ports           []string
	// networks        []string
	// labels          map[string]string       @[str: skip]
	// image           &Image            @[str: skip]
	// engine          &CEngine           @[str: skip]
	// status          ContainerStatus
	// memsize         int // in MB
	// command         string
}

@[params]
pub struct RunArgs {
pub mut:
	cmd string
	// TODO:/..
}

@[params]
pub struct PackageInstallArgs {
pub mut:
	names string
	// TODO:/..
}

// TODO: mimic osal.package_install('mc,tmux,git,rsync,curl,screen,redis,wget,git-lfs')!

// pub fn (mut self Builder) package_install(args PackageInstallArgs) !{
// 	//TODO
// 	names := texttools.to_array(args.names)
// 	//now check which OS, need to make platform function on container level so we know which platform it is
// 	panic("implement")
// }

@[params]
pub struct Command {
pub mut:
	name               string // to give a name to your command, good to see logs...
	cmd                string
	description        string
	timeout            int  = 3600 // timeout in sec
	stdout             bool = true
	stdout_log         bool = true
	raise_error        bool = true // if false, will not raise an error but still error report
	ignore_error       bool              // means if error will just exit and not raise, there will be no error reporting
	work_folder        string            // location where cmd will be executed
	environment        map[string]string // env variables
	ignore_error_codes []int
	scriptpath         string // is the path where the script will be put which is executed
	scriptkeep         bool   // means we don't remove the script
	debug              bool   // if debug will put +ex in the script which is being executed and will make sure script stays
	shell              bool   // means we will execute it in a shell interactive
	retry              int
	interactive        bool = true
	async              bool
	runtime            osal.RunTime
}

pub enum RunTime {
	bash
	python
	heroscript
	herocmd
	v
}

pub fn (mut self Builder) run(cmd Command) ! {
	mut rt := RunTime.bash

	scriptpath := osal.cmd_to_script_path(cmd: cmd.cmd, runtime: cmd.runtime)!

	if cmd.runtime == .heroscript || cmd.runtime == .herocmd {
		self.hero_copy()!
	}

	script_basename := os.base(scriptpath)
	script_path_in_container := '/tmp/${script_basename}'

	self.copy(scriptpath, script_path_in_container)!
	// console.print_debug("copy ${scriptpath} into container '${self.containername}'")
	cmd_str := 'buildah run ${self.id} ${script_path_in_container}'
	// console.print_debug(cmd_str)

	if cmd.runtime == .heroscript || cmd.runtime == .herocmd {
		self.hero_copy()!
	}
	osal.exec(
		name:               cmd.name
		cmd:                cmd_str
		description:        cmd.description
		timeout:            cmd.timeout
		stdout:             cmd.stdout
		stdout_log:         cmd.stdout_log
		raise_error:        cmd.raise_error
		ignore_error:       cmd.ignore_error
		ignore_error_codes: cmd.ignore_error_codes
		scriptpath:         cmd.scriptpath
		scriptkeep:         cmd.scriptkeep
		debug:              cmd.debug
		shell:              cmd.shell
		retry:              cmd.retry
		interactive:        cmd.interactive
		async:              cmd.async
	) or {
		mut epath := pathlib.get_file(path: scriptpath, create: false)!
		c := epath.read()!
		return error('cannot execute:\n${c}\nerror:\n${err}')
	}
}

pub fn (mut self Builder) copy(src string, dest string) ! {
	cmd := 'buildah copy ${self.id} ${src} ${dest}'
	osal.exec(cmd: cmd, stdout: false)!
}

// copies the hero from host into guest
pub fn (mut self Builder) hero_copy() ! {
	if !osal.cmd_exists('hero') {
		crystallib.hero_compile()!
	}
	heropath := osal.cmd_path('hero')!
	self.copy(heropath, '/usr/local/bin/hero')!
}

// copies the hero from host into guest and then execute the heroscript or commandline
pub fn (mut self Builder) hero_execute_cmd(cmd string) ! {
	self.hero_copy()!
	self.run(cmd: cmd, runtime: .herocmd)!
}

pub fn (mut self Builder) hero_execute_script(cmd string) ! {
	self.hero_copy()!
	self.run(cmd: cmd, runtime: .heroscript)!
}

pub fn (mut self Builder) shell() ! {
	cmd := 'buildah run --terminal --env TERM=xterm ${self.id} /bin/bash'
	osal.execute_interactive(cmd)!
}

pub fn (mut self Builder) clean() ! {
	cmd := '
		#set -x
		set +e
		rm -rf /root/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/share/doc
		pacman -Rns $(pacman -Qtdq) --noconfirm
		pacman -Scc --noconfirm	
		rm -rf /var/lib/pacman/sync/*
		rm -rf /tmp/*
		rm -rf /var/tmp/*
		find /var/log -type f -name "*.log" -exec truncate -s 0 {} \\;
		rm -rf /home/*/.cache/*
		rm -rf /usr/share/doc/*
		rm -rf /usr/share/man/*
		rm -rf /usr/share/info/*
		rm -rf /usr/share/licenses/*
		find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name "en*" -exec rm -rf {} \\;
		rm -rf /usr/share/i18n
		rm -rf /usr/share/icons/*
		rm -rf /usr/lib/modules/*
		rm -rf /var/cache/pacman
		journalctl --vacuum-time=1s	

	'
	self.run(cmd: cmd, stdout: false)!
}

pub fn (mut self Builder) delete() ! {
	self.engine.builder_delete(self.containername)!
}

pub fn (mut self Builder) inspect() !BuilderInfo {
	cmd := 'buildah inspect ${self.containername}'
	out := osal.execute_silent(cmd)!
	mut r := json.decode(BuilderInfo, out) or {
		return error('Failed to decode JSON for inspect: ${err}')
	}
	return r
}

// mount the build container to a path and return
pub fn (mut self Builder) mount_to_path() !string {
	cmd := 'buildah mount ${self.containername}'
	out := osal.execute_silent(cmd)!
	return out.trim_space()
}

pub fn (mut self Builder) commit(image_name string) ! {
	cmd := 'buildah commit ${self.containername} ${image_name}'
	osal.exec(cmd: cmd)!
}

pub fn (self Builder) set_entrypoint(entrypoint string) ! {
	cmd := 'buildah config --entrypoint ${entrypoint} ${self.containername}'
	osal.exec(cmd: cmd)!
}

pub fn (self Builder) set_workingdir(workdir string) ! {
	cmd := 'buildah config --workingdir ${workdir} ${self.containername}'
	osal.exec(cmd: cmd)!
}

pub fn (self Builder) set_cmd(command string) ! {
	cmd := 'buildah config --cmd ${command} ${self.containername}'
	osal.exec(cmd: cmd)!
}
