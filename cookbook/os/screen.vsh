#!/usr/bin/env -S v -n -w -enable-globals run

import os
import freeflowuniverse.crystallib.osal.screen

mut scr := screen.new(reset: false)!

// println(scr)

mut s := scr.add(name: 'test')!

mut s2 := scr.add(name: 'redis', cmd: '')!

println(scr)

// s.attach()!
