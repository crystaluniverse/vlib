module juggler

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.clients.daguclient { DAG }
import veb
import json

pub struct Context {
	veb.Context
}

// This is how endpoints are defined in veb. This is the index route
pub fn (j &Juggler[Config]) index(mut ctx Context) veb.Result {
	return ctx.text('Hello V!')
}

// This is how endpoints are defined in veb. This is the index route
@[POST]
pub fn (mut j Juggler[Config]) trigger(mut ctx Context) veb.Result {
	data := ctx.req.data
	event := json.decode(GitEvent, data) or { panic(err) }

	dag := j.get_dag(event) or { return ctx.text('no dag found for repo') }

	cfg := j.config() or { panic(err) }

	mut dagu_client := dagu.get('default',
		url: cfg.dagu_url
	) or { panic(err) }

	return ctx.text('DAG "${dag.name}" started')
}

// get_dag returns the CI/CD DAG for a given repository
fn (mut j Juggler[Config]) get_dag(e GitEvent) ?DAG {
	cfg := j.config() or { panic(err) }
	repo_url := cfg.repo_url
	path := if repo_url.len > 0 {
		mut gs := gittools.get() or { panic(err) }
		mut repo := gs.get_repo(
			pull: true
			reset: false
			url: repo_url
			reload: true
		)!

		path = repo.get_path()!
	} else {
		''
	}

	cicd_dir := pathlib.get_dir(path: path) or { panic('this should never happen') }
	mut repo_cicd_dir := pathlib.get_dir(
		path: '${cicd_dir.path}/git.ourworld.tf/${e.repository.full_name}'
	) or { panic('this should never happen') }

	if !repo_cicd_dir.exists() {
		return none
	}

	// QUESTION: DAG PER ORGANIZATION?

	// use default dag if no branch dag specified
	branch_name := e.ref.all_after_last('/')
	mut branch_dag := pathlib.get_file(
		path: '${repo_cicd_dir.path}/${branch_name}/dag.json'
	) or { panic('this should never happen') }

	mut dag_file := if branch_dag.exists() {
		branch_dag
	} else {
		pathlib.get_file(
			path: '${repo_cicd_dir.path}/dag.json'
		) or { panic('this should never happen') }
	}

	if !dag_file.exists() {
		return none
	}
	dag_json := dag_file.read() or { panic('this should never happen') }
	return json.decode(DAG, dag_json) or { panic('failed to decode ${err}') }
}
