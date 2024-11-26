module main

pub struct Doc {
pub mut:
	items []DocItem
}

type DocItem = Table | Text

pub struct Text {
pub mut:
	content string
}

pub struct Table {
pub mut:
	content string
	nr      int
}

fn do() ! {
	mut doc := Doc{}
	doc.items << Text{
		content: '1'
	}
	doc.items << Table{
		content: '2'
	}

	mut b := doc.items[1]
	if mut b is Table {
		// doc.items[1].nr = 2 //this one wont work
		b.nr = 2 // this works
	}

	println(doc)
}

fn main() {
	do() or { panic(err) }
}
