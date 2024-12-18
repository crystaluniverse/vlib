module builder

import os
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.ui
import v.embed_file

const crystalpath_ = os.dir(@FILE) + '/../'

pub struct BootStrapper {
pub mut:
	embedded_files map[string]embed_file.EmbedFileData @[skip; str: skip]
}

@[params]
pub struct BootstrapperArgs {
pub mut:
	name  string = 'bootstrap'
	addr  string // format:  root@something:33, 192.168.7.7:222, 192.168.7.7, despiegk@something
	reset bool
	debug bool
}

fn (mut bs BootStrapper) load() {
	bs.embedded_files['install_base.sh'] = $embed_file('../../scripts/install_base.sh')
	bs.embedded_files['install_hero.sh'] = $embed_file('../../scripts/install_hero.sh')
}

// to use do something like: export NODES="195.192.213.3" .
pub fn bootstrapper() BootStrapper {
	mut bs := BootStrapper{}
	bs.load()
	return bs
}

pub fn (mut bs BootStrapper) run(args_ BootstrapperArgs) ! {
	mut args := args_
	addr := texttools.to_array(args.addr)
	mut b := new()!
	mut counter := 0
	for a in addr {
		counter += 1
		name := '${args.name}_${counter}'
		mut n := b.node_new(ipaddr: a, name: name)!
		n.crystal_install()!
		n.hero_install()!
	}
}

pub fn (mut node Node) upgrade() ! {
	mut bs := bootstrapper()
	install_base_content_ := bs.embedded_files['install_base.sh'] or { panic('bug') }
	install_base_content := install_base_content_.to_string()
	cmd := '${install_base_content}\n'
	node.exec_cmd(
		cmd:         cmd
		period:      48 * 3600
		reset:       false
		description: 'upgrade operating system packages'
	)!
}

pub fn (mut node Node) hero_install() ! {
	console.print_debug('install hero')
	mut bs := bootstrapper()
	install_hero_content_ := bs.embedded_files['install_hero.sh'] or { panic('bug') }
	install_hero_content := install_hero_content_.to_string()
	if node.platform == .osx {
		// we have no choice then to do it interactive
		myenv := node.environ_get()!
		homedir := myenv['HOME'] or { return error("can't find HOME in env") }
		node.exec_silent('mkdir -p ${homedir}/hero/bin')!
		node.file_write('${homedir}/hero/bin/install.sh', install_hero_content)!
		node.exec_silent('chmod +x ${homedir}/hero/bin/install.sh')!
		node.exec_interactive('${homedir}/hero/bin/install.sh')!
	} else if node.platform == .ubuntu {
		myenv := node.environ_get()!
		homedir := myenv['HOME'] or { return error("can't find HOME in env") }
		node.exec_silent('mkdir -p ${homedir}/hero/bin')!
		node.file_write('${homedir}/hero/bin/install.sh', install_hero_content)!
		node.exec_silent('chmod +x ${homedir}/hero/bin/install.sh')!
		node.exec_interactive('${homedir}/hero/bin/install.sh')!
	}
}

pub fn (mut node Node) dagu_install() ! {
	console.print_debug('install dagu')
	if !osal.cmd_exists('dagu') {
		_ = bootstrapper()
		node.exec_silent('curl -L https://raw.githubusercontent.com/yohamta/dagu/main/scripts/downloader.sh | bash')!
	}
}

@[params]
pub struct CrystalInstallArgs {
pub mut:
	reset bool
}

pub fn (mut node Node) crystal_install(args CrystalInstallArgs) ! {
	mut bs := bootstrapper()
	install_base_content_ := bs.embedded_files['install_base.sh'] or { panic('bug') }
	install_base_content := install_base_content_.to_string()

	if args.reset {
		console.clear()
		console.print_debug('')
		console.print_stderr('will remove: .vmodules, crystal lib code and ~/hero')
		console.print_debug('')
		mut myui := ui.new()!
		toinstall := myui.ask_yesno(
			question: 'Ok to reset?'
			default:  true
		)!
		if !toinstall {
			exit(1)
		}
		os.rmdir_all('${os.home_dir()}/.vmodules')!
		os.rmdir_all('${os.home_dir()}/hero')!
		os.rmdir_all('${os.home_dir()}/code/github/freeflowuniverse/crystallib')!
		os.rmdir_all('${os.home_dir()}/code/github/freeflowuniverse/webcomponents')!
	}

	cmd := '
		${install_base_content}
		
		rm -f /usr/local/bin/hero
		freeflow_dev_env_install

		~/code/github/freeflowuniverse/crystallib/install.sh
		
		echo HERO, V, CRYSTAL ALL INSTALL OK
		echo WE ARE READY TO HERO...
		
		'
	console.print_debug('executing cmd ${cmd}')
	node.exec_cmd(cmd: cmd)!
}

@[params]
pub struct CrystalUpdateArgs {
pub mut:
	sync_from_local bool // will sync local crystal lib to the remote, then cannot use git
	sync_full       bool // sync the full crystallib repo
	sync_fast       bool = true // don't hash the files, there is small chance on error
	git_reset       bool // will get the code from github at remote and reset changes
	git_pull        bool // will pull the code but not reset, will give error if it can't reset	
	branch          string
}

// execute vscript on remote node

pub fn (mut node Node) crystal_update(args_ CrystalUpdateArgs) ! {
	mut args := args_

	if args.sync_from_local && (args.git_reset || args.git_pull) {
		return error('if sync is asked for crystal update, then cannot use git to get crystal')
	}

	if args.sync_from_local {
		if args.sync_full {
			node.sync_code('crystal', crystalpath_ + '/..', '~/code/github/freeflowuniverse/crystallib',
				args.sync_fast)!
		} else {
			node.sync_code('crystal_lib', crystalpath_, '~/code/github/freeflowuniverse/crystallib/crystallib',
				args.sync_fast)!
		}
		return
	}
	mut branchstr := ''
	if args.branch.len > 0 {
		branchstr = 'git checkout ${args.branch} -f && git pull' // not sure latest git pull needed
	}
	if args.git_reset {
		args.git_pull = false
		node.exec_cmd(
			cmd: '
			cd ~/code/github/freeflowuniverse/crystallib
			rm -f .git/index
			git fetch --all
			git reset HEAD --hard
			git clean -xfd		
			git checkout . -f				
			${branchstr}
			'
		)!
	}
	if args.git_pull {
		node.exec_cmd(
			cmd: '
			cd ~/code/github/freeflowuniverse/crystallib
			git pull
			${branchstr}		
			'
		)!
	}
}

pub fn (mut node Node) sync_code(name string, src_ string, dest string, fast_rsync bool) ! {
	mut src := pathlib.get_dir(path: os.abs_path(src_), create: false)!
	node.upload(
		source:     src.path
		dest:       dest
		ignore:     [
			'.git/*',
			'_archive',
			'.vscode',
			'examples',
		]
		delete:     true
		fast_rsync: fast_rsync
	)!
}

// sync local crystal code to rmote and then compile hero
pub fn (mut node Node) hero_compile_sync() ! {
	if !node.file_exists('~/code/github/freeflowuniverse/crystallib/cli/readme.md') {
		node.crystal_install()!
	}
	node.crystal_update()!
	node.exec_cmd(
		cmd: '
		~/code/github/freeflowuniverse/crystallib/install.sh
		~/code/github/freeflowuniverse/crystallib/cli/hero/compile_debug.sh		
		'
	)!
}

pub fn (mut node Node) hero_compile() ! {
	if !node.file_exists('~/code/github/freeflowuniverse/crystallib/cli/readme.md') {
		node.crystal_install()!
	}
	node.exec_cmd(
		cmd: '
		~/code/github/freeflowuniverse/crystallib/cli/hero/compile_debug.sh		
		'
	)!
}

@[params]
pub struct VScriptArgs {
pub mut:
	path            string
	sync_from_local bool   // will sync local crystal lib to the remote
	git_reset       bool   // will get the code from github at remote and reset changes
	git_pull        bool   // will pull the code but not reset, will give error if it can't reset
	branch          string // can only be used when git used
}

pub fn (mut node Node) vscript(args_ VScriptArgs) ! {
	mut args := args_
	node.crystal_update(
		sync_from_local: args.sync_from_local
		git_reset:       args.git_reset
		git_pull:        args.git_pull
		branch:          args.branch
	)!
	mut p := pathlib.get_file(path: args.path, create: false)!

	node.upload(source: p.path, dest: '/tmp/remote_${p.name()}')!
	node.exec_cmd(
		cmd: '
		cd /tmp/remote
		v -w -enable-globals /tmp/remote_${p.name()}
		'
	)!
}
