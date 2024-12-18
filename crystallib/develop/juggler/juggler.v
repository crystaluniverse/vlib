module juggler

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.sysadmin.startupmanager
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.data.markdownparser
import freeflowuniverse.crystallib.osal
import veb
import freeflowuniverse.crystallib.baobab.actor

// Juggler is a Continuous Integration Juggler that listens for triggers from gitea repositories.
pub struct Juggler {
	actor.Actor
	veb.StaticHandler
	veb.Middleware[Context]
pub:
	name        string
	host        string
	port        int
	username    string
	password    string
	secret      string
	config_path string
	url         string
	repo_path   string // local path to the itenv repository defining dag's per repos
}

// get_repo_playbook returns the CI/CD playbook for a given repository
fn (j Juggler) get_repo_playbook(args Repository) ?playbook.PlayBook {
	if args.host == '' {
		panic('this should never happen')
	}

	host := if args.host == 'github.com' {
		'github'
	} else {
		args.host
	}

	cicd_dir := pathlib.get_dir(path: j.config_path) or {
		panic('this should never happen, juggler configuration gone wrong')
	}

	mut repo_cicd_dir := pathlib.get_dir(
		path: '${cicd_dir.path}/${host}/${args.owner}/${args.name}'
	) or { panic('this should never happen') }

	if !repo_cicd_dir.exists() {
		return none
	}

	// use default dag if no branch dag specified
	mut branch_dir := pathlib.get_dir(
		path: '${repo_cicd_dir.path}/${args.branch}'
	) or { panic('this should never happen') }

	// use branch's own playbook if defined, else use the one for the repo
	pb := if branch_dir.exists() {
		playbook.new(path: branch_dir.path) or { panic('this should never happen') }
	} else {
		playbook.new(path: repo_cicd_dir.path) or { panic('this should never happen') }
	}

	return pb
}

pub fn (j Juggler) info() string {
	mut str := '=============== Juggler ===============\n\n'
	str += 'User Interface:\n- url: http://${j.host}:${j.port}\n- status: running\n'
	str += '\nWebhook:\n- enpoint: ${j.host}:${j.port}/trigger\n- secret: ${j.secret}\n'
	str += '\n======================================='
	return str
}

pub fn (mut j Juggler) get_triggers(e Event) ![]Trigger {
	triggers := j.osis.generic_list[Trigger]()!
	return triggers.filter(j.is_triggered(it, e))
}

pub fn (mut j Juggler) get_scripts(t Trigger) ![]Script {
	scripts := j.osis.generic_list[Script]()!
	mut triggered_scripts := []Script{}
	for _, script in scripts {
		if script.id in t.script_ids {
			triggered_scripts << script
		}
	}
	return triggered_scripts
}

pub enum ScriptCategory {
	@none
	hero
	vlang
	shell
	hybrid
}

// get_script gets the script to be run by an event
fn (mut j Juggler) get_script(event Event) ?Script {
	// if event !is GitEvent { panic('implement') }

	repo := j.osis.generic_get[Repository](event.object_id) or {
		panic('this hopefully doesnt happen')
	}

	if repo.host == '' {
		panic('this should never happen')
	}

	host := if repo.host == 'github.com' {
		'github'
	} else {
		repo.host
	}

	cicd_dir := pathlib.get_dir(path: j.config_path) or {
		panic('this should never happen, juggler configuration gone wrong')
	}

	mut repo_cicd_dir := pathlib.get_dir(
		path: '${cicd_dir.path}/${host}/${repo.owner}/${repo.name}'
	) or { panic('this should never happen') }

	// use default dag if no branch dag specified
	mut default_dir := pathlib.get_dir(
		path: '${repo_cicd_dir.path}/default'
	) or { panic('this should never happen') }

	// use default dag if no branch dag specified
	mut branch_dir := pathlib.get_dir(
		path: '${repo_cicd_dir.path}/${repo.branch}'
	) or { panic('this should never happen') }

	// use branch's own playbook if defined, else use the one for the repo
	return if branch_dir.exists() {
		Script{
			path: branch_dir.path
		}
	} else if default_dir.exists() {
		Script{
			path: default_dir.path
		}
	} else {
		none
	}
}

pub fn (mut j Juggler) update_plays() ! {
	plays := j.osis.generic_list[Play]()!
	mut sm := startupmanager.get()!

	for mut play in plays.filter(it.status == .running || it.status == .starting) {
		sm_status := sm.status('juggler_play${play.id}') or {
			panic('failed to get sm status ${err}')
		}
		play.status = match sm_status {
			.activating { Status.running }
			.active { Status.running }
			.deactivating { Status.running }
			.failed { Status.error }
			.inactive { Status.success }
			.unknown { Status.error }
		}
		if play.status == .error || play.status == .success {
			// sm.ended()
		}
		j.osis.generic_set[Play](play) or { panic(err) }
	}
}
