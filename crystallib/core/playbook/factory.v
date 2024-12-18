module playbook

import freeflowuniverse.crystallib.core.base

@[params]
pub struct PlayBookNewArgs {
pub mut:
	path       string
	text       string
	git_url    string
	git_pull   bool
	git_branch string
	git_reset  bool
	prio       int = 50
	priorities map[int]string // filter and give priority, see filtersort method to know how to use
	session    ?&base.Session
}

// get a new playbook, can scan a directory or just add text
// ```
// path string
// text string
// git_url string
// git_pull bool
// git_branch string
// git_reset bool
// session &base.Session
// ```
pub fn new(args_ PlayBookNewArgs) !PlayBook {
	mut args := args_

	mut c := base.context()!

	mut s := c.session_new()!

	mut plbook := PlayBook{
		session: &s
	}
	if args.path.len > 0 || args.text.len > 0 || args.git_url.len > 0 {
		plbook.add(
			path:       args.path
			text:       args.text
			git_url:    args.git_url
			git_pull:   args.git_pull
			git_branch: args.git_branch
			git_reset:  args.git_reset
			prio:       args.prio
			session:    args.session
		)!
	}

	if args.priorities.len > 0 {
		plbook.filtersort(priorities: args.priorities)!
	}

	return plbook
}
