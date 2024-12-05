module card

pub struct Card {
pub:
	title string
	subtitle string
	content string
	url string
}

pub fn (card Card) html() string {
	style := if card.url != '' {
		'cursor: pointer'
	} else {''}
	return $tmpl('templates/card.html')
}