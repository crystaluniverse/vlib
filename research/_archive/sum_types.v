module main

type Executor = ExecutorLocal | ExecutorSSH

struct ExecutorSSH {
	a string
}

struct ExecutorLocal {
	a string
}

fn (mut e ExecutorSSH) ping() string {
	return 'pongSSH'
}

fn (mut e ExecutorLocal) ping() string {
	return 'pongLOCAL'
}

fn new(local bool) Executor {
	if local {
		return ExecutorLocal{}
	} else {
		return ExecutorSSH{}
	}
}

fn do() ? {
	mut l := new(true)
	mut ssh := new(false)

	println(l.ping())
	println(ssh.ping())
}

fn main() {
	do() or { panic(err) }
}
