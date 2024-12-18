module osal

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools

// update the package list
pub fn package_refresh() ! {
	platform_ := platform()

	if cmd_exists('nix-env') {
		// means nix package manager is installed
		// nothing to do
		return
	}
	if platform_ == .ubuntu {
		exec(cmd: 'apt-get update') or { return error('Could not update packages\nerror:\n${err}') }
		return
	} else if platform_ == .osx {
		exec(cmd: 'brew update') or { return error('Could not update packages\nerror:\n${err}') }
		return
	} else if platform_ == .alpine {
		exec(cmd: 'apk update') or { return error('Could not update packages\nerror:\n${err}') }
		return
	} else if platform_ == .arch {
		exec(cmd: 'pacman -Syu --noconfirm') or {
			return error('Could not update packages\nerror:\n${err}')
		}
		return
	}
	return error("Only ubuntu, alpine, arch and osx is supported for now. Found \"${platform_}\"")
}

// install a package will use right commands per platform
pub fn package_install(name_ string) ! {
	names := texttools.to_array(name_)

	// if cmd_exists('nix-env') {
	// 	// means nix package manager is installed
	// 	names_list := names.join(' ')
	// 	console.print_header('package install: ${names_list}')
	// 	exec(cmd: 'nix-env --install ${names_list}') or {
	// 		return error('could not install package using nix:${names_list}\nerror:\n${err}')
	// 	}
	// 	return
	// }

	name := names.join(' ')
	console.print_header('package install: ${name}')
	platform_ := platform()
	cpu := cputype()
	if platform_ == .osx {
		if cpu == .arm {
			exec(cmd: 'arch --arm64 brew install ${name}') or {
				return error('could not install package: ${name}\nerror:\n${err}')
			}
		} else {
			exec(cmd: 'brew install ${name}') or {
				return error('could not install package:${name}\nerror:\n${err}')
			}
		}
	} else if platform_ == .ubuntu {
		exec(
			cmd: '
			export TERM=xterm
			export DEBIAN_FRONTEND=noninteractive
			apt install -y ${name}  -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --allow-downgrades --allow-remove-essential --allow-change-held-packages
			'
		) or { return error('could not install package:${name}\nerror:\n${err}') }
	} else if platform_ == .alpine {
		exec(cmd: 'apk add ${name}') or {
			return error('could not install package:${name}\nerror:\n${err}')
		}
	} else if platform_ == .arch {
		exec(cmd: 'pacman --noconfirm -Su ${name}') or {
			return error('could not install package:${name}\nerror:\n${err}')
		}
	} else {
		return error('Only ubuntu, alpine and osx supported for now')
	}
}

// Remove a package using the appropriate command for each platform
pub fn package_remove(name_ string) ! {
	names := texttools.to_array(name_)
	name := names.join(' ')
	console.print_header('package remove: ${name}')
	platform_ := platform()
	cpu := cputype()

	if platform_ == .osx {
		if cpu == .arm {
			exec(cmd: 'arch --arm64 brew uninstall ${name}', ignore_error: true)!
		} else {
			exec(cmd: 'brew uninstall ${name}', ignore_error: true)!
		}
	} else if platform_ == .ubuntu {
		exec(
			cmd:          '
            export TERM=xterm
            export DEBIAN_FRONTEND=noninteractive
            apt remove -y ${name} --allow-change-held-packages
			apt autoremove -y
            '
			ignore_error: true
		)!
	} else if platform_ == .alpine {
		exec(cmd: 'apk del ${name}', ignore_error: true)!
	} else if platform_ == .arch {
		exec(cmd: 'pacman --noconfirm -R ${name}', ignore_error: true)!
	} else {
		return error('Only ubuntu, alpine and osx supported for now')
	}
}
