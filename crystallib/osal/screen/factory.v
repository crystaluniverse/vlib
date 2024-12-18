module screen

// import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.screen
import os
import time
import freeflowuniverse.crystallib.ui.console

@[heap]
pub struct ScreensFactory {
pub mut:
	screens []Screen
}

@[params]
pub struct ScreensNewArgs {
pub:
	reset bool
}

// return screen instance
pub fn new(args ScreensNewArgs) !ScreensFactory {
	mut t := ScreensFactory{}
	t.scan()!
	if args.reset {
		t.reset()!
	}
	return t
}

pub fn init_screen_object(item_ map[string]string) Screen {
	mut item := Screen{}
	state_item := item_['state'] or { panic('bug') }
	item.state = match state_item.trim('() ').to_lower() {
		'detached' { .detached }
		else { .unknown }
	}
	pre := item_['pre'] or { panic('bug') }
	item.pid = pre.all_before('.').trim_space().int()
	item.name = pre.all_after('.').trim_space()
	return item
}

// loads screen screen, populate the object
pub fn (mut self ScreensFactory) scan() ! {
	self.screens = []Screen{}
	os.execute('screen -wipe  > /dev/null 2>&1') // make sure its all clean
	res := os.execute('screen -ls')
	if res.exit_code > 1 {
		return error('could not find screen or other error, make sure screen is installed.\n${res.output}')
	}
	if res.output.contains('No Sockets found') {
		return
	}
	// there is stuff to parses

	res1 := texttools.remove_empty_lines(res.output)
		.split_into_lines()
		.filter(it.starts_with(' ') || it.starts_with('\t'))
		.join_lines()
	mut res2 := texttools.to_list_map('pre,state', res1, '').map(init_screen_object(it))
	for mut item in res2 {
		if self.exists(item.name) {
			return error('duplicate screen with name: ${item.name}')
		}
		self.screens << item
	}
	// console.print_debug(self.str())
}

pub struct ScreenAddArgs {
pub mut:
	name   string @[requred]
	cmd    string
	reset  bool
	start  bool = true
	attach bool
}

// print list of screen screens
pub fn (mut self ScreensFactory) add(args_ ScreenAddArgs) !Screen {
	mut args := args_
	if args.cmd == '' {
		args.cmd = '/bin/bash'
	}
	if args.name.len < 3 {
		return error('name needs to be at least 3 chars.')
	}
	if self.exists(args.name) {
		if args.reset {
			self.kill(args.name)!
		} else {
			return self.get(args.name)!
		}
	}
	self.screens << Screen{
		name: args.name
		cmd:  args.cmd
	}
	if args.start {
		self.start(args.name)!
	}
	mut myscreen := self.get(args.name) or {
		return error('couldnt start screen with name ${args.name}, was not found afterwards.\ncmd:${args.cmd}\nScreens found.\n${self.str()}')
	}

	if args.attach {
		myscreen.attach()!
	}
	return myscreen
}

// print list of screen screens
pub fn (mut self ScreensFactory) exists(name string) bool {
	for mut screen in self.screens {
		if screen.name == name {
			return true
		}
	}
	return false
}

pub fn (mut self ScreensFactory) get(name string) !Screen {
	for mut screen in self.screens {
		if screen.name == name {
			return screen
		}
	}
	// print_backtrace()
	return error('couldnt find screen with name ${name}\nScreens found.\n${self.str()}')
}

pub fn (mut self ScreensFactory) start(name string) ! {
	mut s := self.get(name) or {
		return error("can't start screen with name:${name}, couldn't find.\nScreens found.\n${self.str()}")
	}
	s.start_()!
	for {
		self.scan()!
		mut s2 := self.get(name) or {
			return error('couldnt start screen with name ${name}, was not found in screen scan.\ncmd:\n${s.cmd}\nScreens found.\n${self.str()}')
		}
		if s2.pid > 0 {
			return
		}
		console.print_debug(s2.str())
		time.sleep(100000)
	}
}

pub fn (mut self ScreensFactory) kill(name string) ! {
	if self.exists(name) {
		mut s := self.get(name) or { return }
		s.kill_()!
	}
	self.scan()!
}

// print list of screen screens
pub fn (mut self ScreensFactory) reset() ! {
	for mut screen in self.screens {
		screen.kill_()!
	}
	self.scan()!
}

pub fn (mut self ScreensFactory) str() string {
	if self.screens.len == 0 {
		return 'No screens found.'
	}
	mut out := '# Screens\n'
	for s in self.screens {
		out += '${s}\n'
	}
	return out
}
