module docker

import freeflowuniverse.crystallib.data.paramsparser { Params }
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.osal { exec, file_write }
import os
import freeflowuniverse.crystallib.ui.console

@[heap]
pub struct DockerComposeRecipe {
pub mut:
	name    string
	content string
	params  Params
	engine  &DockerEngine @[str: skip]
	items   []&ComposeService
	path    string
}

@[params]
pub struct ComposeArgs {
pub mut:
	name        string @[required]
	params      string
	composepath string // can be empty, if empty will be buildpath/compose
}

pub fn (mut e DockerEngine) compose_new(args_ ComposeArgs) DockerComposeRecipe {
	mut args := args_
	if args.name == '' {
		panic('name cannot be empty.')
	}
	if args.composepath == '' {
		args.composepath = '${e.buildpath}/compose'
	}
	return DockerComposeRecipe{
		engine: &e
		name:   args.name
		path:   args.composepath + '/${args.name}'
	}
}

pub fn (mut b DockerComposeRecipe) stop() ! {
	// TODO:
}

pub fn (mut b DockerComposeRecipe) delete() ! {
	b.stop()!
	exec(cmd: 'rm -rf ${b.path} && mkdir -p ${b.path}', stdout: false)!
}

fn (mut b DockerComposeRecipe) render() ! {
	if b.items.len == 0 {
		return error('Cannot find items for the docker compose in service: ')
	}
	b.content = 'version: "3.9"\n'
	b.content += 'services:\n'
	for mut item in b.items {
		c := item.render()!
		b.content += texttools.indent(c, '  ')
	}
}

pub fn (mut b DockerComposeRecipe) start() ! {
	b.render()!
	console.print_debug(b)
	console.print_debug(' start compose file in: ${b.path}')
	os.mkdir_all(b.path)!
	file_write('${b.path}/docker-compose.yml', b.content)!
	for composeitem in b.items {
		for item in composeitem.files {
			filename := item.path.all_after_first('/')
			file_write('${b.path}/${filename}', item.to_string())!
		}
	}

	cmd := '
		set -ex
		cd ${b.path}
		docker compose up -d
		'

	exec(cmd: cmd)!
}
