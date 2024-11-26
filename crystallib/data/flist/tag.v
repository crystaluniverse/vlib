module flist

@[table: 'tag']
pub struct Tag {
pub mut:
	key   string @[primary]
	value string
}

fn (mut f Flist) get_tags() ![]Tag {
	tags := sql f.con {
		select from Tag
	}!

	return tags
}

fn (mut f Flist) add_tag(tag Tag) ! {
	sql f.con {
		insert tag into Tag
	}!
}
