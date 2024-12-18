module installers

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.installers.develapps.vscode
import freeflowuniverse.crystallib.installers.develapps.chrome
import freeflowuniverse.crystallib.installers.virt.podman as podman_installer
import freeflowuniverse.crystallib.installers.virt.buildah as buildah_installer
import freeflowuniverse.crystallib.installers.virt.lima
import freeflowuniverse.crystallib.installers.net.mycelium
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.installers.lang.rust
import freeflowuniverse.crystallib.installers.lang.golang
import freeflowuniverse.crystallib.installers.lang.vlang
import freeflowuniverse.crystallib.installers.lang.crystallib
import freeflowuniverse.crystallib.installers.lang.nodejs
import freeflowuniverse.crystallib.installers.lang.python
import freeflowuniverse.crystallib.installers.web.zola
import freeflowuniverse.crystallib.installers.web.tailwind
import freeflowuniverse.crystallib.installers.hero.heroweb
import freeflowuniverse.crystallib.installers.hero.herodev
import freeflowuniverse.crystallib.installers.sysadmintools.daguserver
import freeflowuniverse.crystallib.installers.sysadmintools.rclone
import freeflowuniverse.crystallib.installers.sysadmintools.prometheus
import freeflowuniverse.crystallib.installers.sysadmintools.grafana
import freeflowuniverse.crystallib.installers.sysadmintools.fungistor
import freeflowuniverse.crystallib.installers.sysadmintools.garage_s3
import freeflowuniverse.crystallib.installers.infra.zinit

@[params]
pub struct InstallArgs {
pub mut:
	names     string
	reset     bool
	uninstall bool
	gitpull   bool
	gitreset  bool
	start     bool
}

pub fn names(args_ InstallArgs) []string {
	names := '
		base
		caddy
		chrome
		crystal
		dagu
		develop
		fungistor
		garage_s3
		golang
		grafana
		hero
		herodev
		heroweb
		lima
		mycelium
		nodejs
		herocontainers
		prometheus
		rclone
		rust
		tailwind
		vlang
		vscode
		zinit
		zola
		'
	mut ns := texttools.to_array(names)
	ns.sort()
	return ns
}

pub fn install_multi(args_ InstallArgs) ! {
	mut args := args_
	mut items := []string{}
	for item in args.names.split(',').map(it.trim_space()) {
		if item !in items {
			items << item
		}
	}
	for item in items {
		match item {
			'base' {
				base.install(reset: args.reset)!
			}
			'develop' {
				base.install(reset: args.reset, develop: true)!
			}
			'rclone' {
				// rclone.install(reset: args.reset)!
				mut rc := rclone.get()!
				rc.install(reset: args.reset)!
			}
			'rust' {
				rust.install(reset: args.reset)!
			}
			'golang' {
				mut g := golang.get()!
				g.install(reset: args.reset)!
			}
			'vlang' {
				vlang.install(reset: args.reset)!
			}
			'crystal' {
				crystallib.install(
					reset:     args.reset
					git_pull:  args.gitpull
					git_reset: args.gitreset
				)!
			}
			'hero' {
				crystallib.hero_install(reset: args.reset)!
			}
			'caddy' {
				// caddy.install(reset: args.reset)!
				// caddy.configure_examples()!
			}
			'chrome' {
				chrome.install(reset: args.reset, uninstall: args.uninstall)!
			}
			'mycelium' {
				mycelium.install(reset: args.reset)!
				mycelium.start()!
			}
			'garage_s3' {
				garage_s3.install(reset: args.reset, config_reset: args.reset, restart: true)!
			}
			'fungistor' {
				fungistor.install(reset: args.reset)!
			}
			'lima' {
				lima.install(reset: args.reset, uninstall: args.uninstall)!
			}
			'herocontainers' {
				mut podman_installer0 := podman_installer.get()!
				mut buildah_installer0 := buildah_installer.get()!

				if args.reset {
					podman_installer0.destroy()! // will remove all
					buildah_installer0.destroy()! // will remove all
				}
				podman_installer0.install()!
				buildah_installer0.install()!
			}
			'prometheus' {
				prometheus.install(reset: args.reset, uninstall: args.uninstall)!
			}
			'grafana' {
				grafana.install(reset: args.reset, uninstall: args.uninstall)!
			}
			'vscode' {
				vscode.install(reset: args.reset)!
			}
			'nodejs' {
				nodejs.install(reset: args.reset)!
			}
			'python' {
				python.install()!
			}
			'herodev' {
				herodev.install()!
			}
			// 'heroweb' {
			// 	heroweb.install()!
			// }
			'dagu' {
				// will call the installer underneith
				mut dserver := daguserver.get()!
				dserver.install()!
				dserver.restart()!
				// mut dagucl:=dserver.client()!
			}
			'zola' {
				mut i2 := zola.get()!
				i2.install()! // will also install tailwind
			}
			'tailwind' {
				mut i := tailwind.get()!
				i.install()!
			}
			'zinit' {
				mut i := zinit.get()!
				i.install()!
			}
			else {
				return error('cannot find installer for: ${item}')
			}
		}
	}
}
