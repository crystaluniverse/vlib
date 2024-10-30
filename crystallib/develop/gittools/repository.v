module gittools

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal
import os
import time
import crypto.md5

// GitRepo holds information about a single Git repository.
pub struct GitRepo {
pub mut:
	gs            &GitStructure @[skip;str: skip] // Reference to the parent GitStructure
	provider      string              // e.g., github.com, shortened to 'github'
	account       string              // Git account name
	name          string              // Repository name
	status_remote GitRepoStatusRemote // Remote repository status
	status_local  GitRepoStatusLocal  // Local repository status
	status_wanted  GitRepoStatusWanted  // what is the status we want?
	config        GitRepoConfig       // Repository-specific configuration
	last_load    int               // Epoch timestamp of the last load from reality
	deploysshkey string //to use with git
}

// this is the status we want, we need to work towards off
pub struct GitRepoStatusWanted {
pub mut:
	branch   string
	tag 	 string
	url      string            // Remote repository URL, is basically the one we want	
	readonly bool			   // if read only then we cannot push or commit, all changes will be reset when doing pull
}

// GitRepoStatusRemote holds remote status information for a repository.
pub struct GitRepoStatusRemote {
pub mut:
	ref_default 		string //is the default branch hash
	branches      map[string]string // Branch name -> commit hash
	tags          map[string]string // Tag name -> commit hash
}

// GitRepoStatusLocal holds local status information for a repository.
pub struct GitRepoStatusLocal {
pub mut:
	branches   map[string]string // Branch name -> commit hash
	branch 	   string //the current branch
	tag        string // If the local branch is not set, the tag may be set
}

// GitRepoConfig holds repository-specific configuration options.
pub struct GitRepoConfig {
pub mut:
	remote_check_period int // Seconds to wait between remote checks (0 = check every time)
}



//just some initialization mechanism
pub fn (mut gitstructure GitStructure) repo_new_from_gitlocation(git_location GitLocation) !&GitRepo {
	mut repo := GitRepo{
		provider: git_location.provider
		name: git_location.name
		account: git_location.account
		gs: &gitstructure
		status_remote: GitRepoStatusRemote{}
		status_local: GitRepoStatusLocal{}
		status_wanted: GitRepoStatusWanted{}				
	}

	gitstructure.repos[repo.name] = &repo

	return &repo

}

//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////



// Commit the staged changes with the provided commit message.
pub fn (mut repo GitRepo) commit(msg string) ! {
	repo.status_update()!
	if repo.need_commit()! {
		if msg == '' {
			return error('Commit message is empty.')
		}
		repo_path := repo.get_path()!
		repo.exec('git add . -A') or { 
				return error('Cannot add to repo: ${repo_path}. Error: ${err}') }
		repo.exec('git commit -m "${msg}"') or { 
				return error('Cannot commit repo: ${repo_path}. Error: ${err}') }
		console.print_green('Changes committed successfully.')
	} else {
		console.print_debug('No changes to commit.')
	}
	repo.load()!
}




// Push local changes to the remote repository.
pub fn (mut repo GitRepo) push() ! {
	repo.status_update()!
	if repo.need_push_or_pull()! {		
		url := repo.get_repo_url()!
		console.print_header('Pushing changes to ${url}')
		// We may need to push the locally created branches
		repo.exec('git push --set-upstream origin ${repo.status_local.branch}')!
		console.print_green('Changes pushed successfully.')
		repo.load()!
	} else {
		console.print_header('Everything is up to date.')
		repo.load()!
	}
}


@[params]
pub struct PullCheckoutArgs {
pub mut:
	submodules bool //if we want to pull for submodules
}

// Pull remote content into the repository.
pub fn (mut repo GitRepo) pull(args_ PullCheckoutArgs) ! {
	repo.status_update()!
	if repo.need_checkout() {
		repo.checkout()!
	}

	repo.exec('git pull') or { return error('Cannot pull repo: ${repo.get_path()!}. Error: ${err}') }

	if args_.submodules {
		repo.update_submodules()!
	}

	repo.load()!
	console.print_green('Changes pulled successfully.')
}

// Checkout a branch in the repository.
pub fn (mut repo GitRepo) checkout() ! {
	repo.status_update()!	
	if repo.status_wanted.readonly{
		repo.reset()!
	}	
	if repo.need_commit()! {
		return error('Cannot checkout branch due to uncommitted changes in ${repo.get_path()!}.')
	}
	if repo.status_wanted.tag.len>0{
		repo.exec('git checkout tags/${repo.status_wanted.tag}')!
	}
	if repo.status_wanted.branch.len>0{
		repo.exec('git checkout ${repo.status_wanted.tag}')!		
	}
}

// Create a new branch in the repository.
pub fn (mut repo GitRepo) branch_create(branchname string) ! {
	repo.exec('git branch -c ${branchname}') or { return error('Cannot Create branch: ${repo.get_path()!} to ${branchname}\nError: ${err}') }
	console.print_green('Branch ${branchname} created successfully.')
}

pub fn (mut repo GitRepo) branch_switch(branchname string) ! {
	repo.exec('git switch ${branchname}') or { return error('Cannot switch branch: ${repo.get_path()!} to ${branchname}\nError: ${err}') }
	console.print_green('Branch ${branchname} switched successfully.')
	repo.status_local.branch = branchname
	repo.status_local.tag = ''
	repo.pull()!
}


// Create a new branch in the repository.
pub fn (mut repo GitRepo) tag_create(tagname string) ! {
	repo_path := repo.get_path()!
	repo.exec('git tag ${tagname}') or { return error('Cannot create tag: ${repo_path}. Error: ${err}') }
	console.print_green('Tag ${tagname} created successfully.')
}

pub fn (mut repo GitRepo) tag_switch(tagname string) ! {
	repo.exec('git checkout ${tagname}') or { 
			return error('Cannot switch to tag: ${tagname}. Error: ${err}') 
		}
	console.print_green('Tag ${tagname} activated.')
	repo.status_local.branch = ''
	repo.status_local.tag = tagname
	repo.pull()!
}

// Create a new branch in the repository.
pub fn (mut repo GitRepo) tag_exists(tag string) !bool {
	repo.exec('git show ${tag}') or { return false }
	return true
}

// Deletes the Git repository
pub fn (mut repo GitRepo) delete() ! {
	repo_path := repo.get_path()!
	repo.cache_delete()!
	osal.rm(repo_path)!
	repo.load()!
}

// Create GitLocation from the path within the Git repository
pub fn (mut gs GitRepo) gitlocation_from_path(path string) !GitLocation {
	if path.starts_with('/') || path.starts_with('~') {
		return error('Path must be relative, cannot start with / or ~')
	}

	//TODO: check that path is inside gitrepo
	//TODO: get relative path in relation to root of gitrepo

	mut git_path := gs.patho()!
	if !os.exists(git_path.path) {
		return error('Path does not exist inside the repository: ${git_path.path}')
	}

	mut branch_or_tag := gs.status_wanted.branch
	if gs.status_wanted.tag.len>0{
		branch_or_tag = gs.status_wanted.tag 
	}

	return GitLocation{
		provider: gs.provider
		account:  gs.account
		name:     gs.name
		branch_or_tag:   branch_or_tag
		path:     path //relative path in relation to git repo
	}
}

// Check if repo path exists and validate fields
pub fn (mut repo GitRepo) init() ! {
	path_string := repo.get_path()!
	if repo.gs.coderoot.path == '' {
		return error('Coderoot cannot be empty')
	}
	if repo.provider == '' {
		return error('Provider cannot be empty')
	}
	if repo.account == '' {
		return error('Account cannot be empty')
	}
	if repo.name == '' {
		return error('Name cannot be empty')
	}

	if !os.exists(path_string) {
		return error('Path does not exist: ${path_string}')
	}

	//TODO: check deploy key has been set in repo
	// if not do git config core.sshCommand "ssh -i /path/to/deploy_key"
	if repo.deploysshkey.len == 0 {
		repo.set_sshkey()!
	}
	//TODO: check tag or branch set on wanted, and not both
}

// Set the ssh key on the repo
fn (mut repo GitRepo) set_sshkey() ! {
	// TODO: We need to check what should be done here.
	key := repo.exec('git config core.sshcommand') or {""}

	hashed_key := md5.hexhash(key)
	file_name := '${hashed_key}.pub'
	sshkeys_path := os.join_path(os.home_dir(), 'hero/cfg/sshkeys')

	if !os.exists(sshkeys_path) {
		os.mkdir_all(sshkeys_path)!
	}

	osal.exec(cmd: "echo ${key} > ${sshkeys_path}/${file_name}")!
	repo.deploysshkey = key
}


// Removes all changes from the repo; be cautious
pub fn (mut repo GitRepo) remove_changes() ! {
	repo.status_update()!
	if repo.has_changes()! {
		console.print_header('Removing changes in ${repo.get_path()!}')
		repo.exec('git reset HEAD --hard && git clean -xfd') or {
			return error("can't remove changes on repo: ${repo.get_path()!}.\n${err}")
			// TODO: we can do this fall back later
			// console.print_header('Could not remove changes; will re-clone ${repo.get_path()!}')
			// mut p := repo.patho()!
			// p.delete()! // remove path, this will re-clone the full thing
			// repo.load_from_url()!
		}
		repo.load()!
	}	
}

//alias for remove changes
pub fn (mut repo GitRepo) reset() ! {
	return repo.remove_changes()
}

// Update submodules
fn (mut repo GitRepo) update_submodules() ! {
	repo.exec('git submodule update --init --recursive') or {
		return error('Cannot update submodules for repo: ${repo.get_path()!}. Error: ${err}')
	}
}



fn (repo GitRepo) exec(cmd_ string) !string {
	repo_path := repo.get_path()!
	cmd:="cd ${repo_path} && ${cmd_}"
	if repo.gs.config.log{
		console.print_green(cmd)
	}
	r:=osal.exec(cmd:cmd, debug:repo.gs.config.debug)!
	return r.output
}

pub fn (mut repo GitRepo) status_update(args StatusUpdateArgs) ! {
	// Check current time vs last check, if needed (check period) then load
	repo.cache_get()! // Ensure we have the situation from redis
	repo.init()!
	current_time := int(time.now().unix())
	if args.reload || repo.last_load == 0
		|| current_time - repo.last_load >= repo.config.remote_check_period {
		repo.load()!
	}
}
