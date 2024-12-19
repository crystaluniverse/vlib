module base

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import os

@[params]
pub struct InstallArgs {
pub mut:
	reset   bool
	develop bool
}

// install base will return true if it was already installed
pub fn install(args_ InstallArgs) ! {
	console.print_header('install base (reset: ${args_.reset})')
	pl := osal.platform()

	mut args := args_

	if pl == .osx && !osal.cmd_exists('brew') {
		args.reset = true
	}

	if args.reset == false && osal.done_exists('platform_prepare') {
		console.print_header('Platform already prepared')
		return
	}

	if pl == .osx {
		console.print_header(' - OSX prepare')
		if !osal.cmd_exists('brew') {
			console.print_header(' -Install Brew')
			osal.exec(
				cmd:    '
					/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
					(echo; echo \'eval "$(/opt/homebrew/bin/brew shellenv)"\') >> ${os.home_dir()}/.zprofile
					reset
					echo
					echo
					echo "execute: \'source ~/.zprofile\'"
					echo "or restart your shell"
					echo "and execute the hero command again"
					echo
					'
				stdout: true
				shell:  true
			) or { return error('cannot install brew, something went wrong.\n${err}') }
		}
		osal.package_install('mc,tmux,git,rsync,curl,screen,wget,git-lfs')!
		if !osal.cmd_exists('uv') {
			osal.exec(cmd:'curl -LsSf https://astral.sh/uv/install.sh | sh')!
		}
	} else if pl == .ubuntu {
		console.print_header(' - Ubuntu prepare')
		osal.package_refresh()!
		osal.package_install('autoconf,libtool,iputils-ping,net-tools,git,rsync,curl,mc,tmux,libsqlite3-dev,xz-utils,git,git-lfs,redis-server,ufw')!
	} else if pl == .alpine {
		console.print_header(' - Alpine prepare')
		osal.package_refresh()!
		osal.package_install('git,curl,mc,tmux,screen,git-lfs,redis-server')!
	} else if pl == .arch {
		console.print_header(' - Arch prepare')
		osal.package_refresh()!
		osal.package_install('rsync,ncdu, git,curl,mc,tmux,screen,git-lfs,redis,unzip,sudo,wget,htop,arch-install-scripts,ufw')!
	} else {
		panic('only ubuntu, arch, alpine and osx supported for now')
	}
	if args.develop {
		develop(reset: args.reset)!
	}
	sshkeysinstall()!
	console.print_header('platform prepare DONE')
	osal.done_set('platform_prepare', 'OK')!
}

pub fn sshkeysinstall(args InstallArgs) ! {
	cmd := '
    mkdir -p ~/.ssh
    if ! grep github.com ~/.ssh/known_hosts > /dev/null
    then
        ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
    fi
    if ! grep git.ourworld.tf ~/.ssh/known_hosts > /dev/null
    then
        ssh-keyscan -t rsa  git.ourworld.tf >> ~/.ssh/known_hosts
    fi    
    git config --global pull.rebase false
	'

	osal.exec(cmd: cmd, stdout: false)!
}

pub fn develop(args InstallArgs) ! {
	console.print_header('install base develop (reset: ${args.reset})')
	pl := osal.platform()

	if args.reset == false && osal.done_exists('crystal_development') {
		return
	}
	if pl == .osx {
		console.print_header(' - OSX prepare for development.')
		osal.package_install('bdw-gc,libpq')!
		if !osal.cmd_exists('clang') {
			osal.execute_silent('xcode-select --install') or {
				return error('cannot install xcode-select --install, something went wrong.\n${err}')
			}
		}
	} else if pl == .ubuntu {
		console.print_header(' - Ubuntu prepare')
		osal.package_install('libgc-dev,make,libpq-dev,build-essential,gcc,tcc')!
		// osal.exec(
		// 	cmd: '
		// 		cd /tmp
		// 		wget https://github.com/bitcoin-core/secp256k1/archive/refs/tags/v0.4.1.tar.gz
		// 		tar -xvf v0.4.1.tar.gz
		// 		cd secp256k1-0.4.1/
		// 		./autogen.sh
		// 		./configure
		// 		make -j 5
		// 		make install
		// 		'
		// )!
	} else if pl == .alpine {
		osal.package_install('libpq-dev,make')!
	} else if pl == .arch {
		osal.package_install('gcc,tcc,make,postgresql-libs')!
	} else {
		panic('only arch, alpine, ubuntu and osx supported for now')
	}
	osal.done_set('crystal_development', 'OK')!
	console.print_header('platform development DONE')
}
