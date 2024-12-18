module docker

@[params]
pub struct CopyArgs {
pub mut:
	from            string
	source          string
	dest            string
	make_executable bool // if set will make the file copied executable
}

pub struct CopyItem {
pub mut:
	from            string
	source          string
	dest            string
	recipe          &DockerBuilderRecipe @[str: skip]
	make_executable bool // if set will make the file copied executable
	// check_embed bool = true
}

// to do something like: 'Add alpine:latest'
pub fn (mut b DockerBuilderRecipe) add_copy(args CopyArgs) ! {
	mut item := CopyItem{
		from:            args.from
		source:          args.source
		dest:            args.dest
		make_executable: args.make_executable
		recipe:          &b
	}
	if item.source == '' {
		return error('source cant be empty, \n${b}')
	}
	if item.dest == '' {
		return error('dest cant be empty, \n${b}')
	}
	b.items << item
}

pub fn (mut i CopyItem) check() ! {
}

pub fn (mut i CopyItem) render() !string {
	mut out := 'COPY ${i.source} ${i.dest}'
	if i.from != '' {
		out = 'COPY --from=${i.from} ${i.source} ${i.dest}\n'
	}
	if i.make_executable {
		out += '\nRUN chmod +x ${i.dest}\n'
	}
	return out
}
