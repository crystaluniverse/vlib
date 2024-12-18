module docker

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools

pub struct ZinitItem {
pub mut:
	name    string
	exec    string   // e.g. redis-server --port 7777
	test    string   // e.g. redis-cli -p 7777 PING
	after   []string // e.g. copy,tmuxp  these are the names of the ones we are depending on
	log     ZinitLogType
	signal  string // could be 'SIGKILL' as well, if not specified then 'SIGTERM'
	oneshot bool   // is the command supposed to stop and only be used one, so not as daemon	
}

enum ZinitLogType {
	ring
	stdout
	null
}

@[params]
pub struct ZinitAddArgs {
pub mut:
	// more info see https://github.com/threefoldtech/zinit/tree/master/docs
	name    string
	exec    string // e.g. redis-server --port 7777
	test    string // e.g. redis-cli -p 7777 PING
	after   string // e.g. 'copy,tmuxp'  these are the names of the ones we are depending on, is comma separated
	log     ZinitLogType
	signal  string // could be 'SIGKILL' as well, if not specified then 'SIGTERM'
	oneshot bool   // is the command supposed to stop and only be used one, so not as daemon
}

// add a zinit to the docker container
// each init will launch a process in the container
// the init files are rendered as yaml files in the build directory and added to the docker at the end
// how to use zinit see: https://github.com/threefoldtech/zinit/tree/master/docs
pub fn (mut b DockerBuilderRecipe) add_zinit_cmd(args ZinitAddArgs) ! {
	if args.name.len < 3 {
		return error('min length of name is 3')
	}
	if args.exec.len < 3 {
		return error('min length of val is 3')
	}
	// TODO: make sure after is lowercase and trimmed
	mut item := ZinitItem{
		name:    args.name
		exec:    args.exec
		test:    args.test
		log:     args.log
		signal:  args.signal
		oneshot: args.oneshot
	}

	mut afterargs := []string{}

	if args.after.len > 0 {
		for afteritem in args.after.split(',') {
			afterargs << afteritem.to_lower().trim_space()
		}
		item.after = afterargs
	}

	b.items << item

	mut zinitfilecontent := ''
	if args.exec.contains('\n') {
		// we now suppose this file is a bash file
		mut content := texttools.dedent(args.exec)
		if !content.trim_space().starts_with('set ') {
			content = 'set -ex\n\n${content}'
		}
		b.write_file(
			dest:            '/cmds/${args.name}.sh'
			content:         content
			make_executable: true
			name:            args.name + '.sh'
		)!
		zinitfilecontent += 'exec: /bin/bash /cmds/${args.name}.sh\n'
	} else {
		zinitfilecontent += 'exec: ${args.exec}\n'
	}

	if args.test.len > 0 {
		zinitfilecontent += 'test: ${args.test}\n'
	}
	if args.after.len > 0 {
		zinitfilecontent += 'after:\n'
		for a in afterargs {
			zinitfilecontent += '  - ${a}\n'
		}
	}
	if args.signal.len > 0 {
		zinitfilecontent += 'signal:\n'
		zinitfilecontent += '  stop: ${args.signal.to_upper()} \n'
	}
	if args.log == .stdout {
		zinitfilecontent += 'log: stdout\n'
	} else if args.log == .ring {
		zinitfilecontent += 'log: ring\n'
	} else if args.log == .null {
		zinitfilecontent += 'log: null\n'
	} else {
		panic('other log')
	}
	if args.oneshot {
		zinitfilecontent += 'oneshot: true\n'
	}
	mut ff := pathlib.get_file(path: b.path() + '/zinit/${args.name}.yaml', create: true)!
	ff.write(zinitfilecontent)!
}

pub fn (mut i ZinitItem) check() ! {
	// nothing much we can do here I guess
}

pub fn (mut i ZinitItem) render() !string {
	// nothing to render only in final step
	return ''
}

// example file format

// exec: redis-server --port 7777
// test: redis-cli -p 7777 PING
// after:
//   - copy
//   - tmuxp
