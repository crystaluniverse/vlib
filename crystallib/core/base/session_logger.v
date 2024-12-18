module base

import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.core.texttools

@[heap]
pub struct Logger {
pub mut:
	session string
}

pub struct LogItem {
pub mut:
	time    ourtime.OurTime
	cat     string
	log     string
	logtype LogType
	session string
}

pub enum LogType {
	stdout
	error
}

pub fn (session Session) logger_new() !Logger {
	// mut l:=log.Log{}
	// l.set_full_logpath('./info.log')
	// l.log_to_console_too()
	return Logger{}
}

@[params]
pub struct LogArgs {
pub mut:
	cat     string
	log     string @[required]
	logtype LogType
}

// cat & log are the arguments .
// category can be any well chosen category e.g. vm
pub fn (mut session Session) log(args_ LogArgs) !LogItem {
	mut args := args_
	args.cat = texttools.name_fix(args.cat)

	mut l := LogItem{
		cat:  args.cat
		log:  args.log
		time: ourtime.now()
		// session: session.guid()
	}

	// TODO: get string output and put to redis

	return l
}

pub fn (li LogItem) str() string {
	return '${li.session}'
}
