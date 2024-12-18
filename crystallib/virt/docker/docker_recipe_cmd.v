module docker

@[params]
pub struct CmdArgs {
pub mut:
	cmd string
}

pub struct CmdItem {
pub mut:
	cmd    string
	recipe &DockerBuilderRecipe @[str: skip]
}

// add run command to docker, is the cmd which is run when docker get's built
pub fn (mut b DockerBuilderRecipe) add_cmd(args CmdArgs) ! {
	mut item := CmdItem{
		cmd:    args.cmd
		recipe: &b
	}
	if item.cmd == '' {
		return error('cmd cannot be empty, \n${b}')
	}
	b.items << item
}

pub fn (mut i CmdItem) check() ! {
	// TODO checks to see if is valid
}

pub fn (mut i CmdItem) render() !string {
	// todo: need to be able to deal with argement e.g. bash /bin/shell.sh   this needs to be 2 elements
	mut cmds := i.cmd.fields()
	for mut cmd_ in cmds {
		cmd_ = "\"${cmd_}\""
	}
	return 'CMD [${cmds.join(', ')}]'
}
