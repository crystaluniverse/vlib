module components

pub struct Head {
pub:
	title string
	links []Link
	scripts []Script
}

pub fn (head Head) html() string {
	return $tmpl('./templates/head.html')
}

pub struct Link {
	rel string
	@as string
	href string
	data_precedence string
	fetch_priority string
}

pub fn (link Link) html() string {
	mut parts := []string{}
	if link.rel != '' {
		parts << 'rel="${link.rel}"'
	}
	if link.href != '' {
		parts << 'href="${link.href}"'
	}
	if link.@as != '' {
		parts << 'as="${link.@as}"'
	}
	if link.fetch_priority != '' {
		parts << 'fetchPriority="${link.fetch_priority}"'
	}
	if link.data_precedence != '' {
		parts << 'as="${link.data_precedence}"'
	}

    return '<link ${parts.join(' ')}/>'
}

pub struct Script {
pub:
	source string
	async string
}

pub fn (script Script) html() string {
	mut parts := []string{}
	if script.source != '' {
		parts << 'src="${script.source}"'
	}
	// if script.async != '' {
		parts << 'async="${script.async}"'
	// }
    return '<script ${parts.join(' ')}></script>'
}

    // <script src="/_next/static/chunks/app/page-940af5eda4277d81.js" async=""></script>
