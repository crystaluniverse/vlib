module docker

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib

@[params]
pub struct WriteFileArgs {
pub mut:
	name            string // such a file needs to have a name
	content         string
	dest            string // where the content will be saved
	make_executable bool   // if true then will be made executable
}

// the content will be written to dest
// all trailing spaces will be removed (dedent)
pub fn (mut r DockerBuilderRecipe) write_file(args WriteFileArgs) ! {
	if args.name == '' {
		return error('name cant be empty, \n ${r}')
	}
	if args.content == '' {
		return error('content cant be empty, \n ${r}')
	}
	if args.dest == '' {
		return error('dest cant be empty, \n ${r}')
	}
	mut ff := pathlib.get_file(path: r.path() + '/snippets/${args.name}', create: true)!
	content := texttools.dedent(args.content)
	ff.write(content)!
	r.add_copy(
		source:          'snippets/${args.name}'
		dest:            args.dest
		make_executable: args.make_executable
	)!
}
