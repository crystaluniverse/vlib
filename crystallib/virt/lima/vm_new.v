module lima

import os
import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal

@[params]
pub struct VMNewArgs {
pub mut:
	name            string = 'default'
	template        TemplateName
	platform        PlatformType
	cpus            int = 8
	memory          i64 = 2000  // in MB
	disk            i64 = 50000 // in MB
	reset           bool
	start           bool = true
	install_crystal bool // if you want crystal to be installed
	install_hero    bool
}

pub enum TemplateName {
	ubuntu
	ubuntucloud
	alpine
	arch
	containerd
}

pub enum PlatformType {
	aarch64
	x86_64
}

// valid template names: .alpine,.arch .
pub fn (mut lf LimaFactory) vm_new(args VMNewArgs) !VM {
	if args.reset {
		lf.vm_delete(args.name)!
	} else {
		return error("can't create vm, does already exist.")
	}

	console.print_header('vm new: ${args.name} (can take a while)')

	iam := os.home_dir().all_after_last('/').trim_space()

	ymlfile := pathlib.get_file(path: '${os.home_dir()}/.lima/${args.name}_ours.yaml', create: true)!
	mut alpine := $tmpl('templates/alpine.yaml')
	mut arch := $tmpl('templates/arch.yaml')
	mut ubuntu := $tmpl('templates/ubuntu.yaml')
	mut ubuntucloud := $tmpl('templates/ubuntucloud.yaml')
	mut containerd := $tmpl('templates/containerd.yaml')

	mut containerd_extra := ''

	match args.template {
		.ubuntu {
			pathlib.template_write(ubuntu, ymlfile.path, true)!
		}
		.arch {
			pathlib.template_write(arch, ymlfile.path, true)!
		}
		.alpine {
			pathlib.template_write(alpine, ymlfile.path, true)!
		}
		.ubuntucloud {
			pathlib.template_write(ubuntucloud, ymlfile.path, true)!
		}
		.containerd {
			pathlib.template_write(containerd, ymlfile.path, true)!
			// containerd_extra =
		}
	}

	memory2 := args.memory / 1000

	mut myarch := 'aarch64'
	if args.platform == .x86_64 {
		myarch = 'x86_64'
	}

	cmd := 'limactl create --name=${args.name} --arch=${myarch}  --cpus=${args.cpus} --memory=${memory2} ${ymlfile.path}'
	console.print_debug('LIMA create:\n${cmd}')
	osal.exec(cmd: cmd, stdout: true)!

	if args.start {
		cmd2 := 'limactl start ${args.name}'
		console.print_debug('LIMA start:\n${cmd}')
		osal.exec(cmd: cmd2, stdout: true)!
	}

	mut vm := lf.vm_get(args.name)!

	if args.install_crystal {
		vm.install_crystal()!
	}

	return vm
}
