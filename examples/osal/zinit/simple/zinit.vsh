#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import time
import freeflowuniverse.crystallib.osal.zinit

zinit.destroy()!
mut z := zinit.new()!

// name      string            [required]
// cmd       string            [required]
// cmd_file  bool  //if we wanna force to run it as a file which is given to bash -c  (not just a cmd in zinit)
// test      string
// test_file bool
// after     []string
// env       map[string]string
// oneshot   bool

p := z.process_new(
	name: 'test'
	cmd:  '/bin/bash'
)!

println(p)
