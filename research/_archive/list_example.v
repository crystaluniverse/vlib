module main

pub struct Doc {
pub mut:
	items []Text
}

pub struct Text {
pub mut:
	content string
}

fn do() ! {
	mut doc := Doc{}
	doc.items << Text{
		content: '1'
	}
	doc.items << Text{
		content: '2'
	}

	mut b := &doc.items[1]
	b.content = '3'

	println(doc)
}

fn main() {
	do() or { panic(err) }
}
