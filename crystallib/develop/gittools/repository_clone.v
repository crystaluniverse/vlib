module gittools


import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal

@[params]
pub struct GitCloneArgs {
pub mut:
	url string
	sshkey string
}



// Clones a new repository into the git structure based on the provided arguments.
pub fn (mut gitstructure GitStructure) clone(args GitCloneArgs) !&GitRepo {
	
	if args.url.len==0{
		return error("url needs to be specified when doing a clone.")
	}
	console.print_header("Git clone from the URL: ${args.url}.")
	git_location := gitstructure.gitlocation_from_url(args.url)!

	mut repo := gitstructure.repo_new_from_gitlocation(git_location)!
	repo.status_wanted.url = args.url

	if args.sshkey.len>0{
		repo.set_sshkey()!
	}

	parent_dir := repo.get_parent_dir(create: true)!

	mut extra:=""
	if gitstructure.config.light{
		extra="--depth 1 --no-single-branch "
	}

	cmd := 'cd ${parent_dir} && git clone ${extra} ${repo.get_repo_url()!} ${repo.name}'
	osal.exec(cmd: cmd) or {
		return error('Cannot clone the repository due to: \n${err}')
	}

	repo.load()!

	console.print_green("The repository '${repo.name}' cloned into ${parent_dir}.")
	
	return repo
}
