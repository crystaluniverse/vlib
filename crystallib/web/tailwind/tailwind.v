module tailwind

import freeflowuniverse.crystallib.installers.web.tailwind as tailwindinstaller
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal
import os

pub struct Tailwind {
pub mut:
	name string
	path pathlib.Path
}

@[params]
pub struct AddArgs {
pub:
	name    string = 'index'
	htmltxt string @[required]
}

pub fn (mut tw Tailwind) add(args AddArgs) ! {
	htmltext := args.htmltxt
	if htmltext.trim_space() == '' {
		print_backtrace()
		return error('html text needs to be not empty.')
	}
	c_index := $tmpl('templates/index.html')
	mut path_index := tw.path.file_get_new('${args.name}.html')!
	path_index.write(c_index)!
}

@[params]
pub struct TailWindArgs {
pub:
	name          string = 'test'
	path_build    string
	content_paths []string // list of sources of the tailwind content, where html with tailwind is
}

// generate the html and open in browser
pub fn new(args TailWindArgs) !Tailwind {
	tailwindinstaller.install()!

	// mut p := pathlib.get_dir(path: '/tmp/flowrift/${args.name}', create: true)!
	mut p := pathlib.get_dir(path: args.path_build, create: true)!

	_ = pathlib.get_dir(
		path: args.path_build
		create: true
	)!

	mut tw := Tailwind{
		path: p
		name: args.name
	}

	content_paths := args.content_paths.map('\'${it}\'').join(',')
	c_tw := $tmpl('templates/tailwind.config.js')
	mut path_tw := p.file_get_new('tailwind.config.js')!
	path_tw.write(c_tw)!

	c_css := $tmpl('templates/input.css').replace('??', '@')
	mut path_css := p.file_get_new('index.css')!
	path_css.write(c_css)!

	return tw
}

// generate the html and open in browser
pub fn (tw Tailwind) compile(source string, dest string) ! {
	// source the go path
	config_path := '${tw.path.path}/tailwind.config.js'
	if os.exists(dest) {
		os.rm(dest)!
	}
	cmd := 'tailwind -c ${config_path} -i ${source} -o ${dest}'
	osal.exec(cmd: cmd)!
}

// // generate the html and open in browser
// pub fn (tw Tailwind) open() ! {
// 	// source the go path
// 	cmd := '
// 		source ${osal.profile_path()}
// 		cd ${tw.path.path}
// 		tailwind -i input.css -o output.css --minify
// 		open index.html
// 		'
// 	osal.exec(cmd: cmd)!
// }
