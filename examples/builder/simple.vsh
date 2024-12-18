#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.builder
import freeflowuniverse.crystallib.core.pathlib
import os

fn do1() ! {
	mut b := builder.new()!
	mut n := b.node_new(ipaddr: 'root@195.192.213.2')!

	n.upload(source: myexamplepath, dest: '/tmp/myexamplepath2')!
	n.download(source: '/tmp/myexamplepath2', dest: '/tmp/myexamplepath2', delete: true)!
}

fn do2() ! {
	mut b := builder.new()!
	mut n := b.node_local()!

	n.upload(source: myexamplepath, dest: '/tmp/myexamplepath3', delete: true)!

	// lets now put something in examplepath3, which should be deleted
	n.file_write('/tmp/myexamplepath3/something', 'something')!
	r := n.file_read('/tmp/myexamplepath3/something')!
	assert r == 'something'

	mut p2 := pathlib.get_dir(path: '/tmp/myexamplepath2')! // needs to exist, and is a dir
	mut p3 := pathlib.get_dir(path: '/tmp/myexamplepath3')!
	h2 := p2.md5hex()!
	mut h3 := p3.md5hex()!
	assert !(h2 == h3)

	n.upload(source: '/tmp/myexamplepath2', dest: '/tmp/myexamplepath3', delete: true)!

	// now hash should be the same, hashes work over all files in a dir
	// its a good trick to compare if 2 directories are the same
	h3 = p3.md5hex()!
	assert h2 == h3

	// there is also a size function, this one is in KByte
	size := p3.size_kb() or { 0 }
	println('size: ${size} KB')
}

do1()
do2()
