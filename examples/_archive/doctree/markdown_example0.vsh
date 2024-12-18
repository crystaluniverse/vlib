#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

// import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import log
import freeflowuniverse.crystallib.data.markdownparser
import os

console.print_header('Print markdown in treeview.')
println('')
// mut session := play.session_new(
// 	context_name: "test"
// 	interactive: true
// )!

// get path local to the current script
path_my_content := '${os.dir(@FILE)}/content'

mut doc1 := markdownparser.new(
	path: '${path_my_content}/links.md'
)!
content1 := doc1.markdown()

println(doc1.treeview())

console.print_header('Markdown output:')
println('')
println(content1)
