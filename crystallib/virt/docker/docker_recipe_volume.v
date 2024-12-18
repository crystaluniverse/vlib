module docker

@[params]
pub struct VolumeArgs {
pub mut:
	mount_points []string
}

pub struct VolumeItem {
pub mut:
	mount_points []string
	recipe       &DockerBuilderRecipe @[str: skip]
}

// to do something like: 'Volume /data'
pub fn (mut b DockerBuilderRecipe) add_volume(args VolumeArgs) ! {
	mut item := VolumeItem{
		mount_points: args.mount_points
		recipe:       &b
	}
	b.items << item
}

pub fn (mut i VolumeItem) check() ! {
	if i.mount_points.len == 0 {
		return error('mount points list cannot be empty')
	}
}

pub fn (mut i VolumeItem) render() !string {
	mut out := 'VOLUME'
	for s in i.mount_points {
		out += ' ${s}'
	}

	return out
}
