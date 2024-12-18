module components

pub struct Page {
pub mut:
	heading PageHeading
	content IComponent
	scripts []Script
}

pub fn (page Page) html() string {
	return $tmpl('./templates/page.html')
}

pub struct PageHeading {
pub:
	title       string
	subtitle    string
	buttons     []Button
	breadcrumbs ?Breadcrumbs
}

pub struct HeadingGroup {
pub:
	components []IComponent
}

pub struct Heading {
pub:
	content string
	level   HeadingLevel
}

pub fn (heading Heading) html() string {
	return '<h${int(heading.level)}>${heading.content}</h${int(heading.level)}>'
}

pub enum HeadingLevel {
	one = 1
	two
	three
	four
	five
}

pub struct Breadcrumbs {
pub:
	anchors []Anchor // anchors for breadcrumbs
	label   string   // label of current page
}

pub fn (breadcrumbs Breadcrumbs) html() string {
	anchors := breadcrumbs.anchors.map('<li>${it.html()}</li>').join_lines()
	return '<nav aria-label="breadcrumb"><ul>\n${anchors}\n<li>${breadcrumbs.label}</li></ul></nav>'
}

pub fn (heading PageHeading) html() string {
	mut breadcrumbs_html := ''
	if breadcrumbs := heading.breadcrumbs {
		breadcrumbs_html = breadcrumbs.html()
	}
	subtitle := if heading.subtitle != '' {
		'\n<p>${heading.subtitle}</p>'
	} else {
		''
	}
	buttons := if heading.buttons.len > 0 {
		'<div>${heading.buttons.map(it.html()).join_lines()}</div>'
	} else {
		''
	}
	return '<header class="grid" style="grid-template-columns: 4fr 1fr;">\n\t<hgroup>\n\t<h1>${heading.title}</h1>${subtitle}\n${breadcrumbs_html}\n</hgroup>\n${buttons}\n</header>'
}

pub fn (component HeadingGroup) html() string {
	return '<hgroup>${component.components.map(it.html()).join_lines()}</hgroup>'
}
