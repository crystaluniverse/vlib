module layout

import freeflowuniverse.crystallib.web.components {IComponent}
import freeflowuniverse.crystallib.web.components.navigation {Sidebar}

pub struct GridLayout {
pub:
	components []IComponent
}

pub fn (layout GridLayout) html() string {
	return '<div class="grid">${layout.components.map(it.html()).join_lines()}</div>'
}

pub struct SidebarLayout {
pub:
	sidebar Sidebar
	components []IComponent
}

pub fn (layout SidebarLayout) html() string {
	return '<div class="grid" style="grid-template-columns: 1fr 4fr">${layout.sidebar.html()}${layout.components.map(it.html()).join_lines()}</div>'
}