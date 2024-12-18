module docker

import freeflowuniverse.crystallib.core.texttools

@[params]
pub struct RunArgs {
pub mut:
	cmd string
}

pub struct RunItem {
pub mut:
	cmd    string
	recipe &DockerBuilderRecipe @[str: skip]
}

// to do something like: 'FROM alpine:latest'
pub fn (mut b DockerBuilderRecipe) add_run(args RunArgs) ! {
	mut item := RunItem{
		cmd:    args.cmd
		recipe: &b
	}
	if item.cmd == '' {
		return error('cmd name cannot be empty')
	}
	b.items << item
}

pub fn (mut i RunItem) check() ! {
	// nothing much we can do here I guess
}

pub fn (mut i RunItem) render() !string {
	mut out := []string{}
	mut first := true
	i.cmd = texttools.dedent(i.cmd)
	for mut line in i.cmd.split_into_lines() {
		line = line.replace('\t', '    ')
		if line == '' {
			continue
		}
		if line.contains('&&') {
			return error("don't use && in scripts")
		}
		if line.trim_space().starts_with('#') {
			continue
		}
		if first {
			out << 'RUN ${line} \\'
			first = false
		} else {
			out << '    && ${line} \\'
		}
	}
	mut out2 := out.join_lines()
	out2 = out2.trim_string_right('\n').trim_string_right('\\')
	return out2
}
