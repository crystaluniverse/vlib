module docker

@[params]
pub struct ExposeARgs {
pub mut:
	ports []string
}

pub struct ExposeItem {
pub mut:
	ports  []string
	recipe &DockerBuilderRecipe @[str: skip]
}

// to do something like: 'Expose 8080/udp'
pub fn (mut b DockerBuilderRecipe) add_expose(args ExposeARgs) ! {
	mut item := ExposeItem{
		ports:  args.ports
		recipe: &b
	}
	b.items << item
}

pub fn (mut i ExposeItem) check() ! {
	if i.ports.len == 0 {
		return error('ports list cannot be empty')
	}
}

pub fn (mut i ExposeItem) render() !string {
	mut out := 'EXPOSE'
	for s in i.ports {
		out += ' ${s}'
	}

	return out
}
