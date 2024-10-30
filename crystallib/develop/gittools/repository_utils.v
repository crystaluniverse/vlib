module gittools

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.sshagent
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.develop.vscode
import freeflowuniverse.crystallib.develop.sourcetree

import os

@[params]
struct GetParentDir{
pub mut:
	create bool
}

fn (repo GitRepo) get_key() string {
	return '${repo.gs.key}:${repo.provider}:${repo.account}:${repo.name}'
}

fn (repo GitRepo) get_cache_key() string {
	return 'git:repos:${repo.gs.key}:${repo.provider}:${repo.account}:${repo.name}'
}

pub fn (repo GitRepo) get_path() !string {
	return '${repo.gs.coderoot.path}/${repo.provider}/${repo.account}/${repo.name}'
}

// Relative path inside the gitstructure, pointing to the repo
pub fn (repo GitRepo) get_relative_path() !string {
	mut mypath := repo.patho()!
	return mypath.path_relative(repo.gs.coderoot.path) or { panic("couldn't get relative path") }
}

pub fn (repo GitRepo) get_parent_dir(args GetParentDir) !string {
	repo_path := repo.get_path()!
	parent_dir := os.dir(repo_path)
	if !os.exists(parent_dir) && !args.create {
		return error('Parent directory does not exist: ${parent_dir}')
	}
	os.mkdir_all(parent_dir)!
	return parent_dir
}

@[params]
pub struct GetRepoUrlArgs {
pub mut:
	with_branch bool // // If true, return the repo URL for an exact branch.
}

// url_get returns the URL of a git address
fn (self GitRepo) get_repo_url(args GetRepoUrlArgs) !string {
	url := self.status_wanted.url
	if url.len != 0 {
		if args.with_branch{
			return '${url}/tree/${self.status_local.branch}'
		}
		return url
	}
	
	if sshagent.loaded() {
		return self.get_ssh_url()!
	} else {
		return self.get_http_url()!
	}
}

fn (self GitRepo) get_ssh_url() !string {
	mut provider := self.provider
	if provider == 'github' {
		provider = 'github.com'
	}
	return 'git@${provider}:${self.account}/${self.name}.git'
}

fn (self GitRepo) get_http_url() !string {
	mut provider := self.provider
	if provider == 'github' {
		provider = 'github.com'
	}
	return 'https://${provider}/${self.account}/${self.name}'
}

// Return rich path object from our library crystal lib
pub fn (repo GitRepo) patho() !pathlib.Path {
	return pathlib.get_dir(path: repo.get_path()!, create: false)!
}

pub fn (mut repo GitRepo) display_current_status() ! {
	staged_changes := repo.get_changes_staged()!
	unstaged_changes := repo.get_changes_unstaged()!

	console.print_header('Staged changes:')
	for f in staged_changes {
		console.print_green('\t- ${f}')
	}

	console.print_header('Unstaged changes:')
	if unstaged_changes.len == 0 {
		console.print_stderr('No unstaged changes; the changes need to be committed.')
		return
	}

	for f in unstaged_changes {
		console.print_stderr('\t- ${f}')
	}
}

// Opens SourceTree for the Git repo
pub fn (repo GitRepo) sourcetree() ! {
	sourcetree.open(path: repo.get_path()!)!
}

// Opens Visual Studio Code for the repo
pub fn (repo GitRepo) open_vscode() ! {
	path := repo.get_path()!
	mut vs_code := vscode.new(path)
	vs_code.open()!
}
