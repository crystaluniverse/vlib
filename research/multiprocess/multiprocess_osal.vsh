#!/usr/bin/env -S v -no-retry-compilation -d use_openssl -enable-globals run

import os
import time
import freeflowuniverse.crystallib.osal

fn new_process(i int) {
	mut job2 := osal.exec(cmd: '/tmp/removeme.sh') or { panic(err) }
	println(job2)
	println('Process ${i} finished ')
}

fn do() ! {
	start := time.now()

	mut threads := []thread{}

	// Start 10 threads
	for i in 0 .. 10 {
		mut mythread := spawn new_process(i)
		threads << mythread
	}

	println('All threads started')

	// Wait for all threads to complete
	threads.wait()

	duration := time.since(start)
	println('Completed all processes in ${duration}')
}

myscript := '#!/bin/bash
set -e

# Loop 60 times
for ((i=1; i<=60; i++))
do
  echo "Loop number: \$i"
  sleep 1
done

echo "Completed 60 loops"
'

os.write_file('/tmp/removeme.sh', myscript)!
os.chmod('/tmp/removeme.sh', 0o755)!

do() or { panic(err) }
