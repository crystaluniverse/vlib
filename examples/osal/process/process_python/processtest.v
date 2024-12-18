module main

import os
import time

fn main() {
	do1() or { panic(err) }
}

fn do1() ! {
	mut p := os.new_process('/opt/homebrew/bin/python3')
	p.set_work_folder('/tmp')
	p.set_redirect_stdio()
	p.use_stdio_ctl = true
	p.use_pgroup = true
	p.set_args(['-i', '-q'])
	p.run()
	// p.set_args("")
	// time.sleep(100 * time.millisecond)
	println('alive: ${p.is_alive()}')
	assert p.is_alive()

	defer {
		p.wait()
		p.close()
	}

	// for {
	// 	println(1)
	// 	println(p.stdout_slurp())
	// 	println(2)
	// 	println(p.stderr_slurp())
	// 	println(3)
	// }
	mut counter := 0
	for {
		counter += 1
		println(counter)
		out := p.pipe_read(.stdout) or { '' }
		if out.len > 0 {
			println('o')
			println(out)
		}
		err := p.pipe_read(.stderr) or { '' }
		if err.len > 0 {
			println('e')
			println(err)
		}
		time.sleep(100 * time.millisecond)
		if counter == 2 {
			p.stdin_write("print('something')\n\n\n")
			// os.fd_close(p.stdio_fd[0])
		}
		if counter == 20 {
			p.stdin_write("print('something else')\n\n\n")
			// os.fd_close(p.stdio_fd[0])
		}
	}
}

fn do2() ! {
	mut p := os.new_process('/opt/homebrew/bin/python3')
	p.set_work_folder('/tmp')
	p.set_redirect_stdio()
	p.use_stdio_ctl = true
	p.use_pgroup = true
	p.run()
	// p.set_args("")
	// time.sleep(100 * time.millisecond)
	println('alive: ${p.is_alive()}')
	assert p.is_alive()

	defer {
		p.wait()
		p.close()
	}

	for {
		fdi := p.stdio_fd[0]
		fdo := p.stdio_fd[1]
		fde := p.stdio_fd[2]
		println(1)
		if os.fd_is_pending(fdo) {
			println(1.1)
			println(os.fd_slurp(fdo))
		}
		println(2)
		if os.fd_is_pending(fde) {
			println(2.1)
			println(os.fd_slurp(fde))
		}
		println(3)
		time.sleep(100 * time.millisecond)
	}
	mut counter := 0
	for {
		counter += 1
		println(counter)
		out := p.pipe_read(.stdout) or { '' }
		if out.len > 0 {
			println('o')
			println(out)
		}
		err := p.pipe_read(.stderr) or { '' }
		if err.len > 0 {
			println('e')
			println(err)
		}
		time.sleep(100 * time.millisecond)
		if counter == 2 {
			p.stdin_write("print('something')\n\n\n")
			os.fd_close(p.stdio_fd[0])
		}
		if counter == 20 {
			p.stdin_write("print('something else')\n\n\n")
			os.fd_close(p.stdio_fd[0])
		}
	}
}
