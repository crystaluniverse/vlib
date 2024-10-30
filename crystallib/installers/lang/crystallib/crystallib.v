module crystallib

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.installers.lang.vlang
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.develop.gittools
import os
// install crystallib will return true if it was already installed

@[params]
pub struct InstallArgs {
pub mut:
	git_pull  bool
	git_reset bool
	reset     bool // means reinstall
}

pub fn install(args InstallArgs) ! {
	// install crystallib if it was already done will return true
	console.print_header('install crystallib (reset: ${args.reset})')
	// osal.package_refresh()!
	if args.reset {
		osal.done_reset()!
	}
	base.install(develop: true)!
	vlang.install(reset: args.reset)!
	vlang.v_analyzer_install(reset: args.reset)!

	mut gs := gittools.get()!
	gs.config.light = true // means we clone depth 1

	mut repo := gs.get_repo(
		pull: args.git_pull
		reset: args.git_reset
		url: 'https://github.com/freeflowuniverse/crystallib/tree/development/crystallib'
	)!

	mut repo2 := gs.get_repo(
		pull: args.git_pull
		reset: args.git_reset
		url: 'https://github.com/freeflowuniverse/webcomponents/tree/main/webcomponents'
	)!

	mut path1 := repo.get_path()!
	mut path2 := repo2.get_path()!

	mut path1p := pathlib.get_dir(path: path1, create: false)!
	mut path2p := pathlib.get_dir(path: path2, create: false)!
	path1p.link('${os.home_dir()}/.vmodules/freeflowuniverse/crystallib', true)!
	path2p.link('${os.home_dir()}/.vmodules/freeflowuniverse/webcomponents', true)!

	// hero_compile()!

	osal.done_set('install_crystallib', 'OK')!
	return
}

// check if crystallibs installed and hero, if not do so
pub fn check() ! {
	if osal.done_exists('install_crystallib') {
		return
	}
	install()!
}

// remove hero, crystal, ...
pub fn uninstall() ! {
	console.print_debug('uninstall hero & crystallib')
	cmd := '
		rm -rf ${os.home_dir()}/hero
		rm -rf ${os.home_dir()}/_code
		rm -f /usr/local/bin/hero
		rm -f /tmp/hero
		rm -f /tmp/install*
		rm -f /tmp/build_hero*
		rm -rf /tmp/execscripts
		'
	osal.execute_stdout(cmd) or { return error('Cannot uninstall crystallib/hero.\n${err}') }
}

pub fn hero_install(args InstallArgs) ! {
	if args.reset == false && osal.done_exists('install_hero') {
		console.print_debug('hero already installed')
		return
	}
	console.print_header('install hero')
	base.install()!
	cmd := '
		cd /tmp
		export TERM=xterm
		curl https://raw.githubusercontent.com/freeflowuniverse/crystallib/development/scripts/install_hero.sh > /tmp/hero_install.sh
		bash /tmp/hero_install.sh
		'
	osal.execute_stdout(cmd) or { return error('Cannot install hero.\n${err}') }
	osal.done_set('install_hero', 'OK')!
	return
}

pub fn hero_compile(args InstallArgs) ! {
	if args.reset == false && osal.done_exists('compile_hero') {
		console.print_debug('hero already compiled')
		return
	}
	console.print_header('compile hero')

	home_dir := os.home_dir()
	cmd_hero := texttools.template_replace($tmpl('templates/hero.sh'))
	osal.exec(cmd: cmd_hero, stdout: false)!

	osal.execute_stdout(cmd_hero) or { return error('Cannot compile hero.\n${err}') }
	osal.done_set('compile_hero', 'OK')!
	return
}

// pub fn update() ! {
// 	console.print_header('package_install update crystallib')
// 	if !(i.state == .reset) && osal.done_exists('install_crystaltools') {
// 		console.print_debug('    package_install was already done')
// 		return
// 	}
// 	osal.execute_silent('cd /tmp && export TERM=xterm && source /root/env.sh && ct_upgrade') or {
// 		return error('Cannot update crystal tools.\n${err}')
// 	}
// 	osal.done_set('update_crystaltools', 'OK')!
// }
