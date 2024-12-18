module fftools

import freeflowuniverse.crystallib.builder
import freeflowuniverse.crystallib.osal.sshagent
import os
import freeflowuniverse.crystallib.ui.console

enum FFToolsState {
	init
	ok
	error
}

@[heap]
pub struct FFTools {
pub mut:
	vscode_extensions_dir string
	github_username       string
	state                 FFToolsState
}

// needed to get singleton
fn init_singleton() &FFTools {
	mut f := FFTools{}
	return &f
}

// singleton creation
const factory = init_singleton()

fn vscode_install() ? {
	mut n := builder.node_local()?

	// check code is installed, if yes don't need to do anything
	if !n.cmd_exists('code') {
		mut url := ''

		if n.platform == builder.PlatformType.osx {
			if n.cputype == builder.CPUType.arm {
				url = 'https://code.visualstudio.com/sha/download?build=stable&os=darwin-arm64'
			} else {
				url = 'https://code.visualstudio.com/sha/download?build=stable&os=darwin'
			}
		}
		mut cmd := $tmpl('install_vscode.sh')
		console.print_debug(cmd)

		n.exec(
			cmd:         cmd
			period:      0
			reset:       false
			description: 'install vscode'
			stdout:      true
			checkkey:    'vscodeinstall'
		) or { return error('cannot install vscode\n' + err.msg() + '\noriginal cmd:\n${cmd}') }
	}

	mut cmd := $tmpl('plugins_vscode.sh')
	console.print_debug(cmd)

	n.exec(
		cmd:         cmd
		period:      0
		reset:       false
		description: 'install vscode'
		stdout:      true
		checkkey:    'vscodeinstall'
	) or { return error('cannot install vscode\n' + err.msg() + '\noriginal cmd:\n${cmd}') }

	// #have to do this workaround on osx, can't do infile -i
	// sed '/Visual Studio/d' ~/.zprofile > /tmp/1 && mv /tmp/1 ~/.zprofile
	// # sed '/Visual Studio/d' ~/.bash_profile > /tmp/1 && mv /tmp/1 ~/.bash_profile

	// cat << EOF >> ~/.zprofile
	// # Add Visual Studio Code (code)
	// export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
	// EOF

	// # cat << EOF >> ~/.bash_profile
	// # # Add Visual Studio Code (code)
	// # export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
	// # EOF

	// # export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"	

	console.print_header('visual studio code installed OK')
}

fn vscode_uninstall() {
	// "${os.env("HOME")}/Library/Application Support/Code"
	// "~/.vscode"
	// TODO

	//$HOME/.config/Code and ~/.vscode.
}

// install fftools (based on ms visual studio code)
pub fn install() ? {
	f := factory
	if f.state == .init {
		vscode_install()?
		// make sure we have ssh key initialized
		sshkey_path := sshagent.load_interactive()?
		console.print_debug(sshkey_path)
	}
}
