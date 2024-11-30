module layout

import freeflowuniverse.crystallib.web.components {IComponent}

pub struct GridLayout {
pub:
	components []IComponent
}

pub fn (layout GridLayout) html() string {
	return '<div class="grid">${layout.components.map(it.html()).join_lines()}</div>'
}