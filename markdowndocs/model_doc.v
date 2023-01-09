module markdowndocs

import pathlib

pub struct Doc {
pub mut:
	items   []DocItem
	path    pathlib.Path
}

type DocItem = Action
	| Actions
	| CodeBlock
	| Comment

	| Header
	| Html
	| Paragraph
	| Table

// fn (mut o DocItem) str() string{
// 	return "$o"
// }


pub fn (doc Doc) wiki() string {
	mut out := ''
	for item in doc.items {
		match item {
			Table { out += item.wiki() }
			Action { out += item.wiki() }
			Actions { out += item.wiki() }
			Header { out += item.wiki() }
			Paragraph { out += item.wiki() }
			Html { out += item.wiki() }
			Comment { out += item.wiki() }
			CodeBlock { out += item.wiki() }
		}
	}
	return out
}


fn (mut doc Doc) process() ! {
	for mut item in doc.items {
		match mut item {
			Table { item.process()! }
			Action { item.process()! }
			Actions { item.process()! }
			Header { item.process()! }
			Paragraph { item.process()! }
			Html { item.process()! }
			Comment { item.process()! }
			CodeBlock { item.process()! }
		}
	}
}

fn (doc Doc) str() string {
	mut out := ''
	for mut item in doc.items {
		match mut item {
			Table { out += item.str() }
			Action { out += item.str() }
			Actions { out += item.str() }
			Header { out += item.str() }
			Paragraph { out += item.str() }
			Html { out += item.str() }
			Comment { out += item.str() }
			CodeBlock { out += item.str() }
		}
	}
	return out
}

pub fn (doc Doc) html() string {
	mut out := ''
	for mut item in doc.items {
		match mut item {
			Table { out += item.str() }
			Action { out += item.str() }
			Actions { out += item.str() }
			Header { out += '<h${item.depth}>${item.content}</h${item.depth}>\n' } //todo: should be moved to item.html()
			Paragraph { out += '<p>${item.content}</p>\n' }
			Html { out += item.str() }
			Comment { out += item.str() }
			CodeBlock { out += item.str() }
		}
	}
	return out
}

pub fn (mut doc Doc) save_wiki() ! {
	doc.path.write(doc.wiki())!
}


// fn (mut doc Doc) last_item_name() string {
// 	return parser.doc.items.last().type_name().all_after_last('.').to_lower()
// }

// // if state is this name will return true
// fn (mut doc Doc) last_item_name_check(tocheck string) bool {
// 	if doc.last_item_name() == tocheck.to_lower().trim_space() {
// 		return true
// 	}
// 	return false
// }