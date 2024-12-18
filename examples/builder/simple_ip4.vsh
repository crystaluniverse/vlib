#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.builder
import freeflowuniverse.crystallib.core.pathlib
import os

mut b := builder.new()!
mut n := b.node_new(ipaddr: 'root@51.195.61.5')!
// mut n := b.node_new(ipaddr: 'info.ourworld.tf')!

println(n)

r := n.exec(cmd: 'ls /')!
println(r)

// n.upload(source: myexamplepath, dest: '/tmp/myexamplepath2')!
// n.download(source: '/tmp/myexamplepath2', dest: '/tmp/myexamplepath2', delete: true)!
