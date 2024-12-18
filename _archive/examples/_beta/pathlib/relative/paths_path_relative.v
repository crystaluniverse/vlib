module main

import freeflowuniverse.crystallib.core.pathlib

fn do() ! {
	// a2 := pathlib.path_relative('/a/b/c/d.txt', '/d.txt')
	// assert a2 == '../../../d.txt'

	println(c)

	// b1:=pathlib.find_common_ancestor(["/a/b/c/d.txt","/a/d.txt"])
	// assert b1=="/a"

	// b2:=pathlib.find_common_ancestor(["/a/b/c/d.txt","/c/d.txt"])
	// assert b2=="/"

	// b3:=pathlib.find_common_ancestor(["/a/b/c/d.txt","/a/b/c/e.txt"])
	// assert b3=="/a/b/c"

	// b4:=pathlib.find_common_ancestor(["/a/b/c/d.txt","/a/b/c/d.txt"])
	// assert b4=="/a/b/c/d.txt"

	// b5:=pathlib.find_common_ancestor(["","/a/b/c/d.txt"])
	// assert b5=="/"

	// b6:=pathlib.find_common_ancestor(["/a/b/c/d.txt",""])
	// assert b6=="/"

	// a1:=pathlib.path_relative("/a/b/c/d.txt","/a/d.txt")
	// assert a1=="../../d.txt"

	// a3:=pathlib.path_relative("/a/b/c/d.txt","/a/b/c/e.txt")
	// assert a3=="e.txt"
	// a4:=pathlib.path_relative("/a/b/c/d.txt","/a/b/d/e.txt")
	// assert a4=="../d/e.txt"
	// a5:=pathlib.path_relative("/a/b/c/d.txt","/a/b/c/d/e/e.txt")
	// assert a5=="d/e/e.txt"
}

fn main() {
	do() or { panic(err) }
}
