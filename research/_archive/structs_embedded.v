module main

pub struct StructB {
pub mut:
	a_link none|StructA @[str: skip]
	c      string = 'koekoe'
}

pub fn (mut s StructB) koekoe() string {
	return s.c
}

pub struct StructA {
pub mut:
	b     none|StructB
	debug bool
}

fn do() ? {
	mut a := StructA{}
	println(a)

	a.b = StructB{}

	if mut a.b is StructB {
		a.b.a_link = &a
		a.b.koekoe()
	}

	println(a)
}

fn main() {
	do() or { panic(err) }
}
