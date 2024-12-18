module docker

@[params]
pub struct WorkDirArgs {
pub mut:
	workdir string
}

pub struct WorkDirItem {
pub mut:
	workdir string
	recipe  &DockerBuilderRecipe @[str: skip]
}

// to do something like: 'FROM alpine:latest'
pub fn (mut b DockerBuilderRecipe) add_workdir(args WorkDirArgs) ! {
	mut item := WorkDirItem{
		recipe:  &b
		workdir: args.workdir
	}
	b.items << item
}

pub fn (mut i WorkDirItem) check() ! {
	// nothing much we can do here I guess
}

pub fn (mut i WorkDirItem) render() !string {
	return 'WORKDIR ${i.workdir}'
}
