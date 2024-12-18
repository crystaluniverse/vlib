module docker

pub struct EnvItem {
pub mut:
	name  string
	value string
}

pub fn (mut b DockerBuilderRecipe) add_env(name string, val string) ! {
	if name.len < 3 {
		return error('min length of name is 3')
	}
	if val.len < 3 {
		return error('min length of val is 3')
	}
	mut item := EnvItem{
		name:  name.to_upper()
		value: val
	}
	b.items << item
}

pub fn (mut i EnvItem) check() ! {
	// nothing much we can do here I guess
}

pub fn (mut i EnvItem) render() !string {
	return "ENV ${i.name}='${i.value}'"
}
