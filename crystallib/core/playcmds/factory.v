module playcmds

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.virt.hetzner
// import freeflowuniverse.crystallib.clients.b2
import freeflowuniverse.crystallib.biz.bizmodel
import freeflowuniverse.crystallib.hero.publishing
import freeflowuniverse.crystallib.threefold.grid4.gridsimulator
// import freeflowuniverse.crystallib.installers.sysadmintools.daguserver
import freeflowuniverse.crystallib.threefold.grid4.farmingsimulator
import freeflowuniverse.crystallib.web.components.slides
// import freeflowuniverse.crystallib.installers.base as base_install
// import freeflowuniverse.crystallib.installers.infra.coredns

pub fn run(mut plbook playbook.PlayBook, dagu bool) ! {
	if dagu {
		hscript := plbook.str()
		scheduler(hscript)!
	}

	play_core(mut plbook)!
	play_ssh(mut plbook)!
	play_git(mut plbook)!
	// play_zola(mut plbook)!
	// play_caddy(mut plbook)!
	// play_juggler(mut plbook)!
	// play_luadns(mut plbook)!
	hetzner.heroplay(mut plbook)!
	// b2.heroplay(mut plbook)!

	farmingsimulator.play(mut plbook)!
	gridsimulator.play(mut plbook)!
	bizmodel.play(mut plbook)!
	slides.play(mut plbook)!
	// base_install(play(mut plbook)!
	// coredns.play(mut plbook)!

	publishing.play(mut plbook)!

	// plbook.empty_check()!

	console.print_header('Actions concluded succesfully.')
}
