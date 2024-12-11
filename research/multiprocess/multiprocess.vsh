#!/usr/bin/env -S v -no-retry-compilation -d use_openssl -enable-globals run

import os
import time

fn new_process(i int)  {
    mut p := os.new_process('/tmp/removeme.sh')
    p.set_redirect_stdio()
    p.run()
    
    println("Process ${i} started")

    // Read output while process runs
    for  {
        if p.is_alive(){
            if p.is_pending(.stdout) { dump( p.stdout_read() ) }
            if p.is_pending(.stderr) { dump( p.stderr_read() ) }
        }else{
            println("process ${i} stopped")
            break        
        }
        time.sleep(100 * time.millisecond)
        //println("${i}")

    }

    // Get final exit code
    code := p.code
    println('Process ${i} finished with exit code: ${code}')
}

fn do() ! {
    start := time.now()

    mut threads := []thread{}
    
    // Start 10 threads
    for i in 0..100 {
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
