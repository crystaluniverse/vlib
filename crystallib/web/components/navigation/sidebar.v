module navigation

import freeflowuniverse.crystallib.web.components {IComponent}

pub struct NavItem {
pub mut:
    href string
    text string
    class_name ?string
}

pub struct Dropdown {
pub mut:
	label string
	items []NavItem
}

pub fn (dropdown Dropdown) html() string {
    return $tmpl('templates/dropdown.html')
}

pub struct Navbar {
pub mut:
    brand NavItem
    // logo Image
    items []IComponent
    user_label string // the label of the user button
}


pub fn (item NavItem) html() string {
    // return ''
    return '<a href="${item.href}">${item.text}</a>'
}

pub struct Sidebar {
pub mut:
    items []IComponent
}

pub fn (sidebar Sidebar) html() string {
    return $tmpl('./templates/sidebar.html')
}
