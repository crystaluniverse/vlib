module docker

// import freeflowuniverse.crystallib.builder

@[params]
pub struct EntryPointArgs {
pub mut:
	cmd string
}

pub struct EntryPointItem {
pub mut:
	cmd    string
	recipe &DockerBuilderRecipe @[str: skip]
}

pub fn (mut b DockerBuilderRecipe) add_entrypoint(args EntryPointArgs) ! {
	mut item := EntryPointItem{
		cmd:    args.cmd
		recipe: &b
	}
	if item.cmd == '' {
		return error('cmd cannot be empty, \n${b}')
	}
	b.items << item
}

pub fn (mut i EntryPointItem) check() ! {
	// TODO checks to see if is valid
}

pub fn (mut i EntryPointItem) render() !string {
	// todo: need to be able to deal with argement e.g. bash /bin/shell.sh   this needs to be 2 elements
	mut cmds := i.cmd.fields()
	for mut cmd_ in cmds {
		cmd_ = "\"${cmd_}\""
	}
	return 'ENTRYPOINT [${cmds.join(', ')}]'
}
