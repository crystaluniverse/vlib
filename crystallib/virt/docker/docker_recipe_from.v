module docker

@[params]
pub struct FromArgs {
pub mut:
	image string
	tag   string
	alias string
}

pub struct FromItem {
pub mut:
	image  string
	tag    string
	recipe &DockerBuilderRecipe @[str: skip]
	alias  string
}

// to do something like: 'FROM alpine:latest'
pub fn (mut b DockerBuilderRecipe) add_from(args FromArgs) ! {
	mut item := FromItem{
		image:  args.image
		tag:    args.tag
		alias:  args.alias
		recipe: &b
	}
	if item.tag == '' {
		if b.engine.localonly {
			item.tag = 'local'
		} else {
			item.tag = 'latest'
		}
	}
	mut prefix := b.prefix
	if b.engine.prefix.len > 0 {
		prefix = b.engine.prefix
	}
	if prefix.len > 0 && !(prefix.ends_with('/')) {
		return error("cannot use prefix if it doesn't end with /, was '${prefix}'")
	}
	item.image = '${prefix}${item.image}'
	if item.image == '' {
		return error('image name cannot be empty')
	}

	b.items << item
}

pub fn (mut i FromItem) check() ! {
	// TODO checks to see if is valid
}

pub fn (mut i FromItem) render() !string {
	if i.alias == '' {
		return 'FROM ${i.image}:${i.tag}'
	} else {
		return 'FROM ${i.image}:${i.tag} AS ${i.alias}'
	}
}
