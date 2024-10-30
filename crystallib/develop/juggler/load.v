module juggler

import os
import freeflowuniverse.crystallib.servers.caddy
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.baobab.actor
import freeflowuniverse.crystallib.data.markdownparser
import freeflowuniverse.crystallib.core.pathlib

fn (mut j Juggler) load(config_path string) ! {
	mut config_dir := pathlib.get_dir(path: config_path)!
	list := config_dir.list() or { panic(err) }
	repo_paths := list.paths.filter(it.path.trim_string_left(config_path).count('/') == 4)

	for path in repo_paths {
		repo_id := j.load_repository(path.path, config_dir.path)!
		script_ids := j.load_scripts_from_path(path)!
		j.load_trigger(repo_id, script_ids)!
	}
}

// loads a repository defined in itenv into juggler backend
// returns repository objects id
fn (mut j Juggler) load_repository(path string, itenv_path string) !u32 {
	relpath := path.trim_string_left(itenv_path).trim('/')
	mut repo := Repository{
		host: relpath.split('/')[0]
		owner: relpath.split('/')[1]
		name: relpath.split('/')[2]
		branch: relpath.split('/')[3]
	}
	if repo.host == 'github' {
		repo.host = 'github.com'
	}
	return j.new_repository(repo)!
}

fn (mut j Juggler) load_trigger(repo_id u32, script_ids []u32) ! {
	repo := j.backend.get[Repository](repo_id)!
	git_trigger := Trigger{
		name: 'git push ${repo.name} [${repo.branch}]'
		description: 'git push ${repo.name} [${repo.branch}]'
		object_id: repo_id
		script_ids: script_ids
	}
	j.new_trigger(git_trigger)!
}

// get_repo_playbook returns the CI/CD playbook for a given repository
fn (j Juggler) get_playbook_dir(args Repository) ?pathlib.Path {
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

	// use default dag if no branch dag specified
	mut default_dir := pathlib.get_dir(
		path: '${repo_cicd_dir.path}/${args.branch}/default'
	) or { panic('this should never happen') }

	// use default dag if no branch dag specified
	mut branch_dir := pathlib.get_dir(
		path: '${repo_cicd_dir.path}/${args.branch}'
	) or { panic('this should never happen') }

	// use branch's own playbook if defined, else use the one for the repo
	return if branch_dir.exists() {
		branch_dir
	} else if default_dir.exists() {
		default_dir
	} else {
		none
	}
}

// returns the path of the fetched repo
fn code_get(cfg Config) !string {
	mut args := cfg

	if 'CODEROOT' in os.environ() && args.coderoot == '' {
		args.coderoot = os.environ()['CODEROOT']
	}

	if args.coderoot.len > 0 {
		// panic('coderoot >0 not supported yet, not imeplemented.')
	}

	mut gs := gittools.get(coderoot: args.coderoot)!
	if args.url.len > 0 {
		repo := gs.get_repo(
			pull: false
			reset: false
			url: cfg.url
		)!
		return repo.get_path()!
	}

	return error('URL must be provided to configure juggler')
}

pub fn (mut j Juggler) load_scripts_from_path(path_ pathlib.Path) ![]u32 {
	mut path := pathlib.get(path_.path)
	list := path.list(dirs_only: true, recursive: false)!

	if list.paths.len > 0 {
		return list.paths.map(j.load_script_from_path(it)!)
	}

	return [j.load_script_from_path(path_)!]
}

pub fn (mut j Juggler) load_script_from_path(path_ pathlib.Path) !u32 {
	mut path := pathlib.get(path_.path)
	mut readme_file := pathlib.get_file(path: '${path.path}/README.md')!

	relpath := path.path.trim_string_left(j.config_path)
	name := if readme_file.exists() {
		readme_doc := markdownparser.new(path: readme_file.path)!
		readme_doc.header_name()!
	} else {
		relpath.all_after('/').all_after('/')
	}

	description := if readme_file.exists() {
		readme_doc := markdownparser.new(path: readme_file.path)!
		paragraph := readme_doc.children[2]
		// TODO: more defensive
		paragraph.children[0].content.trim_space()
	} else {
		''
	}

	mut paths := path.list()!.paths.clone()
	mut category := ScriptCategory.@none

	if paths.any(it.extension() == 'md' || it.extension() == 'hero') {
		category = ScriptCategory.hero
	}
	if paths.any(it.extension() == 'bash' || it.extension() == 'sh') {
		if category == .hero {
			category = ScriptCategory.hybrid
		} else {
			category = ScriptCategory.shell
		}
	}
	if paths.any(it.extension() == 'v' || it.extension() == 'vsh') {
		if category == .hero {
			category = ScriptCategory.hybrid
		} else {
			category = ScriptCategory.vlang
		}
	}

	script := Script{
		name: name
		category: category
		description: description
		url: '${j.url}/src/branch/main/${relpath.trim('/')}'
		path: path.path
	}

	return j.backend.new[Script](script)!
}
