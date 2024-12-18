module hero

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.sysadmin.downloader
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.develop.gittools

// a session is where in execute on actions inside a runner, a runner can have multiple sessions
// as session result in a recipe which is a heroscript which is fully included and has all actions readable what will be done
pub struct Session {
pub mut:
	name     string
	path     pathlib.Path @[skip] // is the base directory of the session
	vars     map[string]string
	actions  []playbook.Action @[skip]
	includes []string
	runner   &Runner @[skip; str: skip]
}

@[params]
pub struct SessionArgs {
pub mut:
	name        string // name given to the session
	reset       bool   // will reset the content as fetched of url when true	
	actions_url string // optional is where the actions are dowloaded from, can be the path of recipe folder right away
	run         bool   // optional, if mentioned then will run all
}

// open a runner a path is the only thing needed, config and everything else needs to come after .
// a runner will get the actions from source and then load them in memory .
// the recipe will be in $runnerpath/recipes/$recipename
// the downloads will be in $runnerpath/downloads/$downloadname
pub fn (mut r Runner) session_new(args_ SessionArgs) !Session {
	mut args := args_

	if args.name.len == 0 {
		return error('Cannot execute session for runner, name not defined.\n${r}')
	}

	args.name = texttools.name_fix(args.name)
	mut p := pathlib.get_dir(path: '${r.path.path}/sessions/${args.name}', create: true)!
	mut session := Session{
		runner: &r
		name:   args.name
		path:   p
	}

	if args.actions_url.len > 0 {
		session.actions_add(reset: args.reset, url: args.actions_url, run: args.run)!
	}

	r.sessions << &session
	return session
}

@[params]
pub struct SessionRecipeArgs {
pub mut:
	recipename string // name given to the session
	name       string // if empty then will be same as recipename
	reset      bool   // will reset the content as fetched of url when true		actions_url string //optional is where the actions are dowloaded from, can be the path of recipe folder right away
	run        bool = true
}

// run a session for an existing recipe
pub fn (mut r Runner) session_recipe_run(args_ SessionRecipeArgs) !Session {
	mut args := args_
	if args.name == '' {
		args.name = args.recipename
	}
	dest := '${r.path.path}/recipes/${args.recipename}'
	return r.session_new(name: args.name, reset: args.reset, run: args.run, actions_url: dest)
}

@[params]
pub struct ActionsAddArgs {
pub mut:
	downloadname string // optional, if mentioned will use that name for download dir
	reset        bool   // will reset the content as fetched of url when true
	url          string // url can be ssh:// http(s):// git:// file:// path:// http(s)file://	
	run          bool   // if the actions added need to be executed right away
}

// get path objext of where the download is
// name can also be a url, will automatically clean it up
pub fn (mut session Session) downloadpath(name_ string) !pathlib.Path {
	mut name := name_
	if name.contains(':') || name.contains('.') {
		name = downloader.getlastname(name)
	} else {
		name = texttools.name_fix(name)
	}
	mut p := pathlib.get_dir(path: '${session.path.path}/downloads/${name}')!
	return p
}

// add actions to the session
pub fn (mut session Session) actions_add(args_ ActionsAddArgs) ! {
	mut args := args_

	if args.url.len < 5 {
		return error("Cannot execute session '${session.name}' for runner, url not defined.\n${session}")
	}

	mut urlpath := pathlib.get(args.url)
	mut actions_path := urlpath.path

	if !(urlpath.exists() && (urlpath.is_dir() || urlpath.is_dir_link())) {
		if args.downloadname == '' {
			args.downloadname = downloader.getlastname(args.url)
		}

		mut downloadpath := session.downloadpath(args.downloadname)!
		if args.reset {
			downloadpath.empty()!
		}

		// if not a dir and not exist we need to download
		// will link if git
		_ := downloader.download(
			url:          args.url
			reset:        args.reset
			dest:         downloadpath.path // is now a dir so files will get in dir
			gitstructure: session.runner.args.gitstructure
		)!
		actions_path = downloadpath.path
	}

	mut ap := playbook.new(path: actions_path)!
	for a in ap.actions {
		session.actions << a
	}

	if args.run {
		session.run()!
	}
}

@[params]
pub struct RunArgs {
pub mut:
	actions_runner_config_enable bool
}

// run the recipes but on
pub fn (mut s Session) run(args RunArgs) ! {
	// lets first resolve the includes and process after including
	mut actionsprocessed := s.actions_include(s.actions)!
	mut actionsprocessed2 := []playbook.Action{}
	mut actionsprocessed3 := []playbook.Action{}
	for mut action in actionsprocessed {
		if action.actor == 'runner' && action.name == 'config' {
			if args.actions_runner_config_enable {
				// only execute when we load the runner
				mut circle := action.params.get_default('circle', '')!
				mut root := action.params.get_default('root', '')!
				if circle.len > 0 {
					s.runner.args.cid = circle
				}
				if root.len > 0 {
					s.runner.args.root = root
				}
				s.runner.path = pathlib.get_dir(path: '${s.runner.args.root}/${s.runner.args.cid}')!
			}
		} else if (action.actor == 'runner' || action.actor == 'session')
			&& action.name == 'var_set' {
			mut name := action.params.get_default('name', '')!
			mut val := action.params.get_default('val', '')!
			if name == '' || val == '' {
				return error('Name or val not specified in ${action}.\n${s}')
			}
			s.var_set(name, val)
		} else {
			actionsprocessed2 << action
		}
	}

	// now resolve all the variables and execute the
	for mut action2 in actionsprocessed2 {
		// action.params.replace(test)
		action2.params.replace(s.vars)

		if (action2.actor == 'runner' || action2.actor == 'session') && action2.name == 'recipe_add' {
			// will add an action can be https file, https git, scp, or local path
			// subdir means we getall dir's under the specified one and link those indepenently
			//!!runner.recipe_add source:'${ROOT}/core/base0' alias:'base0' execute:1 subdir:1

			mut sourceurl := action2.params.get_default('source', '')!
			if sourceurl.len < 5 {
				return error('Cannot include: ${sourceurl}, is <5 chars. \n${s}')
			}
			mut alias := action2.params.get_default('alias', '')!
			if alias.len > 0 {
				alias = texttools.name_fix(alias)
			}
			mut to_execute := action2.params.get_default_false('execute')
			mut is_subdir := action2.params.get_default_false('subdir')
			mut reset := action2.params.get_default_false('reset')

			if is_subdir {
				// will now make a recipe path for each subdir
				if alias.len > 0 {
					return error('cannot have alias while we expect to process subdirs')
				}
				m := downloader.download(
					url:          sourceurl
					reset:        reset
					gitstructure: s.runner.args.gitstructure
				)!
				mut downloadpath := pathlib.get_dir(path: m.path)!
				// needs to be a dir
				mut path_list := downloadpath.list(recursive: false)!
				for mut subdir in path_list.paths {
					// TODO: we use to have dir_list, find cleaner way to replace it
					if !subdir.is_dir() {
						continue
					}
					alias = texttools.name_fix(subdir.name())
					dest := '${s.runner.path.path}/recipes/${alias}'
					if m.downloadtype == .pathdir {
						mut destpath := pathlib.get_dir(path: dest, create: true)!
						subdir.copy(dest: destpath.path)!
					} else if m.downloadtype == .git {
						subdir.link(dest, true)!
					} else {
						return error('can only get subdirs for git and a path dir')
					}
					if to_execute {
						s.runner.session_recipe_run(recipename: alias, reset: reset)!
					}
				}
			} else {
				if alias.len == 0 {
					alias = downloader.getlastname(sourceurl)
				}
				dest := '${s.runner.path.path}/recipes/${alias}'
				_ := downloader.download(
					url:          sourceurl
					reset:        reset
					dest:         dest
					gitstructure: s.runner.args.gitstructure
				)!
				if to_execute {
					s.runner.session_recipe_run(recipename: alias, reset: reset)!
				}
			}
		} else {
			actionsprocessed3 << action2
		}
	}

	s.actions = actionsprocessed3

	s.actions_do()!
}

pub fn (mut s Session) var_set(name string, value string) {
	name2 := texttools.name_fix(name)
	s.vars[name2] = value
}

pub fn (mut s Session) var_get(name string) !string {
	name2 := texttools.name_fix(name)
	if name2 in s.vars {
		return s.vars[name2]
	}
	return error('Could not find ${name} in vars of runner.\n${s}')
}

pub fn (mut s Session) var_exists(name string) bool {
	name2 := texttools.name_fix(name)
	if name2 in s.vars {
		return true
	}
	return false
}

pub fn (mut s Session) str() string {
	mut out := '### session: ${s.name}\n\n'
	for action in s.actions {
		out += '${action}\n\n'
	}
	return out
}
