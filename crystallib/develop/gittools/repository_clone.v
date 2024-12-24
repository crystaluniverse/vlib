module gittools

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal
import os

@[params]
pub struct GitCloneArgs {
pub mut:
	url    string
	sshkey string
}

// Clones a new repository into the git structure based on the provided arguments.
pub fn (mut gitstructure GitStructure) clone(args GitCloneArgs) !&GitRepo {
	if args.url.len == 0 {
		return error('url needs to be specified when doing a clone.')
	}

	console.print_header('Git clone from the URL: ${args.url}.')
	git_location := gitstructure.gitlocation_from_url(args.url)!

	mut repo := gitstructure.repo_new_from_gitlocation(git_location)!
	repo.status_wanted.url = args.url
	repo.status_wanted.branch = git_location.branch_or_tag

	if args.sshkey.len > 0 {
		repo.set_sshkey(args.sshkey)!
	}

	parent_dir := repo.get_parent_dir(create: true)!

	mut extra := ''
	if gitstructure.config.light {
		extra = '--depth 1 --no-single-branch '
	}

	cmd := 'cd ${parent_dir} && git clone ${extra} ${repo.get_http_url()!} ${repo.name}'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Cannot clone the repository due to: \n${result.output}')
	}

	repo.load()!
	if repo.need_checkout() {
		repo.checkout()!
	}

	console.print_green("The repository '${repo.name}' cloned into ${parent_dir}.")

	return repo
}
