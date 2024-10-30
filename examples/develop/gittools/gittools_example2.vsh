#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.osal
import time

// Creates a new file in the specified repository path and returns its name.
fn create_new_file(repo_path string, runtime i64)! string {
	coded_now := time.now().unix()
	file_name := 'hello_world_${coded_now}.py'
	println('Creating a new ${file_name} file.')

	// Create a new file in the repository.
	osal.execute_silent("echo \"print('Hello, World!')\" > ${repo_path}/${file_name}")!
	return file_name
}

// Resets all configurations and caches if needed.
// gittools.cachereset()!

// Initializes the Git structure with the coderoot path.
coderoot := '~/code'
mut gs_default := gittools.new(coderoot: coderoot)!

// Retrieve the specified repository.
mut repo := gs_default.get_repo(name: 'repo3')!

// In case we need to clone it, will clone the repo2 in a folder named repo3
// mut repo := gs_default.get_repo(name: 'repo3' clone: true, url: 'https://github.com/Mahmoud-Emad/repo2.git')!

runtime := time.now().unix()
branch_name := "branch_${runtime}"
tag_name := "tag_${runtime}"
repo_path := repo.get_path()!
mut file_name := create_new_file(repo_path, runtime)!

// Create a new branch to add our changes on it.
// We can simply checkout to the newly created branch, but we need to test the checkout method functionalty.

println('Creating a new \'${branch_name}\' branch...')
repo.create_branch(branch_name: branch_name, checkout: false) or {
	error("Couldn't create branch due to: ${err}")
}

// Checkout to the created branch
println('Checkout to \'${branch_name}\' branch...')
repo.checkout(branch_name: branch_name, pull: false) or {
	error("Couldn't checkout to branch ${branch_name} due to: ${err}")
}

// Check for changes and stage them if present.
if repo.has_changes()! {
	println('Adding the changes...')
	repo.add_changes() or {
		error('Cannot add the changes due to: ${err}')
	}
}

// Check if a commit is needed and commit changes if necessary.
if repo.need_commit()! {
	commit_msg := 'feat: Added ${file_name} file.'
	println('Committing the changes, Commit message: ${commit_msg}.')
	repo.commit(msg: commit_msg) or {
		error('Cannot commit the changes due to: ${err}')
	}
}

// Push changes to the remote repository if necessary.
if repo.need_push()! {
	println('Pushing the changes...')
	repo.push() or {
		error('Cannot push the changes due to: ${err}')
	}
}

if repo.need_pull()! {
	println('Pulling the changes.')
	repo.pull() or {
		error('Cannot pull the changes due to: ${err}')
	}
}

// Checkout to the base branch 
repo.checkout(checkout_to_base_branch: true, pull: true) or {
	error("Couldn't checkout to branch ${branch_name} due to: ${err}")
}

// Create a new tag and add some changes on it then push it to the remote.
println('Creating a new \'${tag_name}\' tag...')
repo.create_tag(tag_name: tag_name, checkout: false) or {
	error("Couldn't create tag due to: ${err}")
}

// Push the created tag.
println('Pushing the tag...')
repo.push(push_tag: true) or {
	error('Cannot push the tag due to: ${err}')
}

// Check if the created tag exists.
println('Check if the created tag exists...')
repo.is_tag_exists(tag_name: tag_name) or {
	println("Tag isn't exists.")
}