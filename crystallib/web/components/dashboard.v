module components

pub struct Dashboard {
pub:
	user string
}

pub fn (component Dashboard) html() string {
	return $tmpl('./templates/dashboard.html')
}