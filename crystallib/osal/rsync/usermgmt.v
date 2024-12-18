module rsync

import freeflowuniverse.crystallib.core.pathlib

pub struct UserManager {
pub mut:
	configpath string = '/etc/rsyncd.secrets'
	users      map[string]User
}

pub struct User {
pub mut:
	name   string
	passwd string
}

@[params]
pub struct UserArgs {
pub mut:
	name   string
	passwd string
}

pub fn (mut self UserManager) user_add(args_ UserArgs) ! {
	mut args := args_
	self.users[args.name] = User{
		name:   args.name
		passwd: args.passwd
	}
}

pub fn usermanager() !UserManager {
	mut self := UserManager{}
	self.load()!
	return self
}

pub fn (mut self UserManager) load(args UserArgs) ! {
	mut p := pathlib.get_file(path: self.configpath, create: true)!
	content := p.read()!
	for line in content.split('\n') {
		if line.trim_space() == '' {
			continue
		}
		if line.contains(':') {
			items := line.split(':')
			if items.len != 2 {
				return error('syntax error in ${self.configpath}.\n${line}')
			}
			self.user_add(name: items[0], passwd: items[1])!
		} else {
			return error('syntax error in ${self.configpath}.\n${line}')
		}
	}
}

// generate the secrets config file
pub fn (mut self UserManager) generate() ! {
}
