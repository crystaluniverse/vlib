module components

import freeflowuniverse.crystallib.data.markdownparser.elements

pub interface ILayout {
    html() string
mut:
    main IComponent
}

pub struct Layout {
pub:
    components []IComponent
}

pub fn (layout Layout) html() string {
    return layout.components.map(it.html()).join('\n')
}

pub fn (layout SiteLayout) html() string {
    return $tmpl('./templates/layout_site.html')
}

pub struct SiteLayout {
pub mut:
    navbar Navbar
    main IComponent
    content elements.Doc
    markdown MarkdownContent
}

pub struct DashboardLayout {
pub mut:
    navbar Navbar
    sidebar IComponent
    main IComponent
    content elements.Doc
    markdown MarkdownContent
}

pub fn (layout DashboardLayout) html() string {
    return $tmpl('./templates/layout_dashboard.html')
}