module gittools

import freeflowuniverse.crystallib.ui.console

// Check and return the status of a repository (whether it needs a commit, pull, or push)
fn get_repo_status(gr GitRepo) !string {
	mut repo := gr
	mut statuses := []string{}

	if repo.need_commit()! {
		statuses << 'COMMIT'
	}
	if repo.need_push_or_pull()! {
		statuses << 'PULL'
		statuses << 'PUSH'
	}
	return statuses.join(', ')
}

// Format repository information for display, including path, tag/branch, and status
fn format_repo_info(repo GitRepo) ![]string {
	status := get_repo_status(repo)!

	tag_or_branch := if repo.status_local.tag.len > 0 {
		'[[${repo.status_local.tag}]]' // Display tag if it exists
	} else {
		'[${repo.status_local.branch}]' // Otherwise, display branch
	}

	relative_path := repo.get_relative_path()!
	return [' - ${relative_path}', tag_or_branch, status]
}

// Print repositories based on the provided criteria, showing their statuses
pub fn (mut gitstructure GitStructure) repos_print(args ReposGetArgs) ! {
	console.print_debug(' #### Overview of repositories:')
	console.print_debug('')

	mut repo_data := [][]string{}

	// Collect repository information based on the provided criteria
	for _, repo in gitstructure.get_repos(args)! {
		repo_data << format_repo_info(repo)!
	}

	// Clear the console and start printing the formatted repository information
	console.clear()
	console.print_lf(1)

	// Display header with optional argument filtering information
	header := if args.str().len > 0 {
		'Repositories: ${gitstructure.coderoot.path} [${args.str()}]'
	} else {
		'Repositories: ${gitstructure.coderoot.path}'
	}
	console.print_header(header)

	// Print the repository information in a formatted array
	console.print_lf(1)
	console.print_array(repo_data, '  ', true) // true -> aligned for better readability
	console.print_lf(5)
}