module components

pub struct Button{
	Unpoly
pub mut:
	onclick string
	typ string
	content string
	navigate string // the route the button is to navigate to, if it is
}

pub fn (button Button) html() string {
	mut btn := button

	if btn.navigate != '' {
		btn.onclick = "up.navigate({url: '${button.navigate}'})"
	}

	mut tags := []string{}
	if btn.onclick != '' {
		tags << 'onclick="${btn.onclick}"'
	}

	return '<button ${tags.join(' ')} ${button.Unpoly.html()}>${button.content}</button>'
}


pub struct Unpoly {
pub:
	up_link string
}

pub fn (unpoly Unpoly) html() string {
	mut str := ''
	if unpoly.up_link != '' {
		str += 'up-link="${unpoly.up_link}"'
	}

	return str
}