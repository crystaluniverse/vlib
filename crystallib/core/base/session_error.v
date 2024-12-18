module base

import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.core.texttools

pub struct ErrorArgs {
pub mut:
	cat       string
	error     string
	errortype ErrorType
}

pub struct ErrorItem {
pub mut:
	time      ourtime.OurTime
	cat       string
	error     string
	errortype ErrorType
	session   string // the unique name for the session
}

pub enum ErrorType {
	uknown
	value
}

pub fn (mut session Session) error(args_ ErrorArgs) !ErrorItem {
	mut args := args_
	args.cat = texttools.name_fix(args.cat)

	mut l := ErrorItem{
		cat:       args.cat
		error:     args.error
		errortype: args.errortype
		time:      ourtime.now()
		session:   session.name
	}

	// TODO: get string output and put to redis

	return l
}
