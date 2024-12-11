module components

pub struct Group {
pub:
	components []IComponent
}

pub fn (group Group) html() string {
	components := group.components.map(it.html()).join('\n')
	return '<div role="group">\n${components}\n</div>'
}