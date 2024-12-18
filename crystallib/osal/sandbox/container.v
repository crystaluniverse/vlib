module sandbox

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.osal
import json
import os

pub struct Container {
pub mut:
	name        string
	path_config pathlib.Path
	path_root   pathlib.Path
	path_io     pathlib.Path
	startcmd    []string
	factory     &Factory @[skip; str: skip]
}

@[params]
pub struct ContainerArgs {
pub mut:
	name        string   = 'ubuntu'
	path_prefix string   = '/tmp'
	path_config string   = '@PREFIX/data/@NAME/config'
	path_root   string   = '@PREFIX/data/containers/@NAME/fs'
	path_io     string   = '@PREFIX/data/containers/@NAME/io'
	startcmd    []string = ['/bin/bash']
}

pub fn (mut f Factory) container_new(args_ ContainerArgs) !Container {
	mut args := args_
	args.name = texttools.name_fix(args.name)
	args.path_config = args.path_config.replace('@NAME', args.name)
	args.path_root = args.path_root.replace('@NAME', args.name)
	args.path_io = args.path_io.replace('@NAME', args.name)
	args.path_config = args.path_config.replace('@PREFIX', args.path_prefix)
	args.path_root = args.path_root.replace('@PREFIX', args.path_prefix)
	args.path_io = args.path_io.replace('@PREFIX', args.path_prefix)

	os.mkdir_all(args.path_config)!
	os.mkdir_all(args.path_root)!

	mut c := Container{
		name:        args.name
		path_config: pathlib.get_dir(path: args.path_config, create: true)!
		path_root:   pathlib.get_dir(path: args.path_root, create: true)!
		path_io:     pathlib.get_dir(path: args.path_io, create: true)!
		startcmd:    args.startcmd
		factory:     &f
	}

	return c
}

pub fn (mut c Container) debootstrap(args_ DebootstrapArgs) ! {
	// mut path:="${c.factory.path_images.path}/lunar"
	// osal.exec(cmd:"rsync -rav --delete ${path}/ ${c.path_root.path}/")!

	// mut path:="${f.path_images.path}/lunar"
	// mut patho:= pathlib.get_dir(path:path,true)!
	// if args.reset{
	// 	patho.empty()!
	// }
	osal.exec(cmd: 'debootstrap ${args_.release} ${c.path_root.path} ${args_.repository}')!
}

pub fn (mut c Container) start() ! {
	mut configpath := c.path_config.file_get_new('config.json')!
	commandargs := json.encode(c.startcmd)
	t := $tmpl('templates/config.json')
	configpath.write(t)!

	osal.exec(
		cmd:         'runc run ${c.name}'
		work_folder: c.path_config.path
		debug:       true
	)!
}
