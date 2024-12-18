module context

import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.data.paramsparser
import os

pub struct LogItem {
pub mut:
	session &Session @[skip; str: skip]
	time    ourtime.OurTime
	cat     string
	log     string
}

@[params]
pub struct LogArgs {
pub mut:
	cat string
	log string @[required]
}

// cat & log are the arguments .
// category can be any well chosen category e.g. vm
pub fn (session Session) log(args_ LogArgs) !LogItem {
	mut args := args_
	args.cat = texttools.name_fix(args.cat)

	mut l := LogItem{
		session: &session
		cat:     args.cat
		log:     args.log
		time:    ourtime.now()
	}

	// TODO: get string output and put to redis

	return l
}

pub fn (li LogItem) str() string {
	return '${li.session.sid}'
}
