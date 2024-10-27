module components

pub struct NavItem {
pub mut:
    href string
    text string
    class_name ?string
}

pub struct Navbar {
pub mut:
    brand NavItem
    logo Image
    items []IComponent
    user_label string // the label of the user button
}

pub struct Nav {
pub mut:
    items []IComponent
}

pub fn (nav Nav) html() string {
    // return ''
    return '<nav>${nav.items.map(it.html()).join("\n")}</nav>'
}

pub struct Sidebar {
pub mut:
    items []NavItem
}

pub struct Image {
pub:
    source string
}

pub fn (item NavItem) html() string {
    return '<img src="${item}" alt="Logo" style="height: 40px;">'
}

pub fn (image Image) html() string {
    return '<img src="${image.source}" alt="Logo" style="height: 40px;">'
}

pub fn (navbar Navbar) html() string {
    return $tmpl('./templates/navbar.html')
}

pub fn (sidebar Sidebar) html() string {
    return $tmpl('./templates/sidebar.html')
}
