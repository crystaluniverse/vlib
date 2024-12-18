module main

// Define sum types for optional struct references
pub type OptionalStructA = StructA | none
pub type OptionalStructB = StructB | none

pub struct StructB {
pub mut:
	a_link OptionalStructA @[str: skip]
	c      string = 'koekoe'
}

pub fn (mut s StructB) koekoe() string {
	return s.c
}

pub struct StructA {
pub mut:
	b     OptionalStructB
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
