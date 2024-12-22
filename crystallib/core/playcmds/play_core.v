module playcmds

import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.ui.console

// !!context.configure
//     name:'test'
//     coderoot:...
//     interactive:true

pub fn play_core(mut plbook playbook.PlayBook) ! {
	for mut action in plbook.find(filter: 'context.configure')! {
		mut p := action.params
		mut session := plbook.session

		if p.exists('interactive') {
			session.interactive = p.get_default_false('interactive')
		}

		if p.exists('coderoot') {
			panic('implement')
			_ := p.get_path_create('coderoot')!

			_ := gittools.get()!
		}
		action.done = true
	}

	for mut action in plbook.find(filter: 'session.')! {
		_ := action.params
		_ := plbook.session

		//!!session.env_set key:'JWT_SHARED_KEY' val:'...'

		action.done = true
	}

	for action_ in plbook.find(filter: 'play.*')! {
		if action_.name == 'run' {
			console.print_debug('play run:${action_}')
			mut action := *action_
			mut playrunpath := action.params.get_default('path', '')!
			if playrunpath.len == 0 {
				action.name = 'pull'
				action2 := play_git_action(action)!
				playrunpath = action2.params.get_default('path', '')!
			}
			if playrunpath.len == 0 {
				return error("can't run a heroscript didn't find url or path.")
			}
			console.print_debug('play run path:${playrunpath}')
			plbook.add(path: playrunpath)!
		}
		if action_.name == 'echo' {
			content := action_.params.get_default('content', "didn't find content")!
			console.print_header(content)
		}
	}

	// for mut action in plbook.find(filter: 'core.coderoot_set')! {
	// 	mut p := action.params
	// 	if p.exists('coderoot') {
	// 		coderoot := p.get_path_create('coderoot')!
	// 		mut gs := session.context.gitstructure()!
	// 		if gs.rootpath.path != coderoot {
	// 			mut db := session.context.contextdb.db_get(dbname: 'context')!
	// 			db.set('coderoot', coderoot)!
	// 			session.context.gitstructure_reload()!
	// 		}
	// 	} else {
	// 		return error('coderoot needs to be specified')
	// 	}
	// 	action.done = true
	// }

	// for mut action in plbook.find(filter: 'core.params_context_set')! {
	// 	mut p := action.params
	// 	for param in p.params {
	// 		session.context.params.set(param.key, param.value)
	// 	}
	// 	action.done = true
	// }

	// for mut action in plbook.find(filter: 'core.params_session_set')! {
	// 	mut p := action.params
	// 	for param in p.params {
	// 		session.params.set(param.key, param.value)
	// 	}
	// 	action.done = true
	// }
}
