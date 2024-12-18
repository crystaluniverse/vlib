module docker

import freeflowuniverse.crystallib.ui.console

@[params]
pub struct PackageArgs {
pub mut:
	name  string
	names []string
}

pub struct PackageItem {
pub mut:
	names    []string
	recipe   &DockerBuilderRecipe @[str: skip]
	platform PlatformType
}

// add one of more name (alpine packages), no need to do update, upgrade first,
pub fn (mut b DockerBuilderRecipe) add_package(args PackageArgs) ! {
	mut package := PackageItem{
		recipe:   &b
		names:    args.names
		platform: b.platform
	}
	if args.name == '' && args.names == [] {
		return error('name or names cannot be empty, name can be comma separated')
	}
	if args.name.contains(',') {
		for item2 in args.name.split(',') {
			package.names << item2.trim_space()
		}
	} else {
		if args.name != '' {
			package.names << args.name.trim_space()
		}
	}

	b.check_from_statement()!

	// now check if we after each from find an apk upgrade
	mut updatedone := false
	for item3 in b.items {
		if item3 is FromItem {
			updatedone = false
		}
		if item3 is RunItem {
			if item3.cmd.contains('apk upgrade') {
				updatedone = true
			}
		}
	}
	if updatedone == false {
		if b.platform == .alpine {
			// means we first need to do an update
			b.add_run(
				cmd: '
				#rm -rf /tmp/* 
				#rm -rf /var/cache/name/*
				apk update
				apk upgrade
				'
			) or { return error('Failed to add run') }
		} else if b.platform == .ubuntu {
			b.add_run(
				cmd: '
				apt-get update
				apt-get install -y apt-transport-https'
			)!
		} else {
			panic('implement for ubuntu')
		}
	}

	// lets now check of the package has already not been set before
	for package0 in b.items {
		if package0 is PackageItem {
			for packagename in package0.names {
				for packagenamecompare in package.names {
					if packagenamecompare == packagename {
						// we found a double
						return error('Cannot add the package again, there is a double. ${packagename} \n${b}')
					}
				}
			}
		}
	}
	// console.print_debug(package)
	if package.names.len == 0 {
		return error('could not find package names.\n ${b}\nARGS:\n${args}')
	}
	b.items << package
}

pub fn (mut i PackageItem) check() ! {
	// maybe over time we can in redis hold a list of name possible names, so we can check at compile time if its going to work
}

pub fn (mut i PackageItem) render() !string {
	mut names := ''
	for name in i.names {
		names += ' ${name} '
	}
	mut pkg_manager := 'apk add --no-cache'
	if i.platform == .ubuntu {
		pkg_manager = 'apt-get -y install'
	}
	return 'RUN ${pkg_manager} ${names}'
}
