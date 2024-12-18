module vscode

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import os

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

pub fn install(args_ InstallArgs) ! {
	mut args := args_
	// base.install()!
	console.print_header('install vscode')
	if !args.reset && osal.done_exists('install_vscode') && osal.cmd_exists('code') {
		console.print_debug(' - already installed')
		return
	}
	mut url := ''
	if osal.platform() in [.alpine, .arch, .ubuntu] {
		if osal.cputype() == .arm {
			url = 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-arm64'
		} else {
			url = 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64'
		}
	} else if osal.platform() == .osx {
		if osal.cputype() == .arm {
			url = 'https://code.visualstudio.com/sha/download?build=stable&os=cli-darwin-arm64'
		} else {
			url = 'https://code.visualstudio.com/sha/download?build=stable&os=cli-darwin-x64'
		}
	}
	console.print_debug(' download ${url}')
	_ = osal.download(
		url:         url
		minsize_kb:  5000
		reset:       args.reset
		dest:        '/tmp/vscode.zip'
		expand_file: '/tmp/download/vscode'
	)!

	osal.cmd_add(
		cmdname: 'code'
		source:  '/tmp/download/vscode/code'
		reset:   true
	)!

	extensions_install(default: true)!

	osal.done_set('install_vscode', 'OK')!
}

@[params]
pub struct ExtensionsInstallArgs {
pub mut:
	extensions string
	default    bool = true
}

pub fn extensions_install(args_ ExtensionsInstallArgs) ! {
	mut args := args_
	mut items := []string{}
	for item in args.extensions.split(',').map(it.trim_space()) {
		if item.trim_space() == '' {
			continue
		}
		if item !in items {
			items << item
		}
	}
	default := [
		'golang.go',
		'ms-azuretools.vscode-docker',
		'ms-python.autopep8',
		'ms-python.python',
		'ms-vscode-remote.remote-ssh',
		'ms-vscode-remote.remote-ssh-edit',
		'ms-vscode-remote.remote-containers',
		'ms-vscode.cmake-tools',
		'ms-vscode.makefile-tools',
		'ms-vscode.remote-explorer',
		'ms-vscode.remote-repositories',
		'ms-vsliveshare.vsliveshare',
		'redhat.vscode-yaml',
		'rust-lang.rust-analyzer',
		'sumneko.lua',
		'shd101wyy.markdown-preview-enhanced',
		'TakumiI.markdowntable',
		'telesoho.vscode-markdown-paste-image',
		'tamasfe.even-better-toml',
		'tomoki1207.pdf',
		'VOSCA.vscode-v-analyzer',
		'yzhang.markdown-all-in-one',
		'zamerick.vscode-caddyfile-syntax',
		'zxh404.vscode-proto3',
	]
	if args.default {
		for item in default {
			if item !in items {
				items << item
			}
		}
	}
	for item in items {
		cmd := 'code --install-extension ${item}'
		console.print_debug(' - extension install: ${item}')
		res := os.execute(cmd)
		if res.exit_code > 0 {
			return error("could not install visual studio code extension:'${item}'.\n${res}")
		}
	}
}

pub fn extensions_list() ![]string {
	cmd := 'code  --list-extensions'
	res := os.execute(cmd)
	if res.exit_code > 0 {
		return error('could not list visual studio code extensions.\n${res}')
	}
	mut res2 := []string{}
	for i in res.output.split_into_lines().map(it.trim_space()) {
		if i.trim_space() == '' {
			continue
		}
		res2 << i
	}
	return res2
}
