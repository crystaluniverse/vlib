module qemu

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
	cpus            int = 8
	memory          i64 = 2000  // in MB
	disk            i64 = 20000 // in MB
	reset           bool
	start           bool = true
	install_crystal bool // if you want crystal to be installed
	install_hero    bool
}

pub enum TemplateName {
	ubuntu
	alpine
	arch
}

// valid template names: .alpine,.arch .
pub fn (mut lf QemuFactory) vm_new(args VMNewArgs) !VM {
	if args.reset {
		lf.vm_delete(args.name)!
	} else {
		return error("can't create vm, does already exist.")
	}

	console.print_header('vm new: ${args.name} (can take a while)')

	iam := os.home_dir().all_after_last('/').trim_space()

	ymlfile := pathlib.get_file(path: '${os.home_dir()}/.qemu/${args.name}_ours.yaml', create: true)!
	mut alpine := $tmpl('templates/alpine.yaml')
	mut arch := $tmpl('templates/arch.yaml')
	mut ubuntu := $tmpl('templates/ubuntu.yaml')

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
	}

	memory2 := args.memory / 1000

	cmd := 'qemuctl create --name=${args.name} --arch aarch64 --cpus=${args.cpus} --memory=${memory2} ${ymlfile.path}'
	osal.exec(cmd: cmd, stdout: true)!

	if args.start {
		cmd2 := 'qemuctl start ${args.name}'
		osal.exec(cmd: cmd2, stdout: true)!
	}

	mut vm := lf.vm_get(args.name)!

	if args.install_crystal {
		vm.install_crystal()!
	}

	return vm
}
