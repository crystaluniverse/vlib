module components

pub struct Form {
pub:
	id      string
	content IComponent
}

pub fn (form Form) html() string {
	return '<form id="${form.id}">${form.content.html()}</form>'
}

pub struct IncrementalInput {
pub:
	label string
	typ   string
}

pub fn (input IncrementalInput) html() string {
	return $tmpl('templates/incremental.html')
}
