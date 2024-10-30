module coredns

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.develop.gittools
import os

pub fn configure(args_ InstallArgs) ! {
	mut args := args_
	mut gs := gittools.get()!
	mut repo_path := ''

	if args.config_url.len > 0 {
		mut repo := gs.get_repo(
			url: args.config_url
		)!
		repo_path = repo.get_path()!

		args.config_path = repo_path
	}

	if args.config_path.len == 0 {
		args.config_path = '${os.home_dir()}/hero/cfg/Corefile'
	}

	if args.dnszones_url.len > 0 {
		mut repo := gs.get_repo(
			url: args.dnszones_url
		)!
		repo_path = repo.get_path()!
		args.dnszones_path = repo_path
	}

	if args.dnszones_path.len == 0 {
		args.dnszones_path = '${os.home_dir()}/hero/cfg/dnszones'
	}

	mycorefile := $tmpl('templates/Corefile')
	mut path := pathlib.get_file(path: args.config_path, create: true)!
	path.write(mycorefile)!
}

pub fn example_configure(args_ InstallArgs) ! {
	mut args := args_

	exampledbfile := $tmpl('templates/db.example.org')

	mut path_testzone := pathlib.get_file(
		path: '${args_.dnszones_path}/db.example.org'
		create: true
	)!
	path_testzone.template_write(exampledbfile, true)!
}
