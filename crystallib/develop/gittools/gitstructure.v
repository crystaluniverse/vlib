module gittools

import crypto.md5
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.clients.redisclient
import os
import freeflowuniverse.crystallib.ui.console

pub struct GitStructureConfig {
pub mut:
	coderoot     string
	light        bool = true // If true, clones only the last history for all branches (clone with only 1 level deep)
	log          bool = true // If true, logs git commands/statements
	debug        bool = true
	ssh_key_name string
}

fn rediskey(coderoot string) string {
	key := md5.hexhash(coderoot)
	return 'git:config:${key}'
}

// GitStructure holds information about repositories within a specific code root.
// This structure keeps track of loaded repositories, their configurations, and their status.
@[heap]
pub struct GitStructure {
pub mut:
	key      string              // Unique key representing the git structure (default is hash of $home/code).
	config   GitStructureConfig  // Configuration settings for the git structure.
	coderoot pathlib.Path        // Root directory where repositories are located.
	repos    map[string]&GitRepo // Map of repositories, keyed by their unique names.
	loaded   bool                // Indicates if the repositories have been loaded into memory.
}

//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

// Loads all repository information from the filesystem and updates from remote if necessary.
// Use the reload argument to force reloading from the disk.
//
// Args:
// - args (StatusUpdateArgs): Arguments controlling the reload behavior.
pub fn (mut gitstructure GitStructure) load(args StatusUpdateArgs) ! {
	mut processed_paths := []string{}
	// println("1")
	gitstructure.load_recursive(gitstructure.coderoot.path, mut processed_paths)!
	// println("2")

	if args.reload {
		mut ths := []thread !{}
		redisclient.reset()! // make sure redis is empty, we don't want to reuse
		for _, mut repo_ in gitstructure.repos {
			mut myfunction := fn (mut repo GitRepo) ! {
				// println("reload repo ${repo.name} on ${repo.get_path()!}")
				redisclient.reset()!
				redisclient.checkempty()
				repo.status_update(reload: true)!
			}

			ths << spawn myfunction(mut repo_)
		}
		console.print_debug('loaded all threads for git on ${gitstructure.coderoot.path}')

		for th in ths {
			th.wait()!
		}
		// console.print_debug("threads finished")
		// exit(0)
	}

	gitstructure.init()!
}

// just some initialization mechanism
pub fn (mut gitstructure GitStructure) init() ! {
	if gitstructure.config.debug {
		gitstructure.config.log = true
	}
	if gitstructure.repos.keys().len == 0 {
		gitstructure.load()!
	}
}

// Recursively loads repositories from the provided path, updating their statuses.
//
// Args:
// - path (string): The path to search for repositories.
// - processed_paths ([]string): List of already processed paths to avoid duplication.
fn (mut gitstructure GitStructure) load_recursive(path string, mut processed_paths []string) ! {
	path_object := pathlib.get(path)
	relpath := path_object.path_relative(gitstructure.coderoot.path)!

	// Limit the recursion depth to avoid deep directory traversal.
	if relpath.count('/') > 4 {
		return
	}

	items := os.ls(path) or {
		return error('Cannot load gitstructure because directory not found: ${path}')
	}

	for item in items {
		current_path := os.join_path(path, item)

		if os.is_dir(current_path) {
			if os.exists(os.join_path(current_path, '.git')) {
				// Initialize the repository from the current path.
				mut repo := gitstructure.repo_init_from_path_(current_path)!
				// repo.status_update()!

				key_ := repo.get_key()
				path_ := repo.get_path()!

				if processed_paths.contains(key_) || processed_paths.contains(path_) {
					return error('Duplicate repository detected.\nPath: ${path_}\nKey: ${key_}')
				}

				processed_paths << path_
				processed_paths << key_
				gitstructure.repos[key_] = &repo
				continue
			}

			if item.starts_with('.') || item.starts_with('_') {
				continue
			}
			// Recursively search in subdirectories.
			gitstructure.load_recursive(current_path, mut processed_paths)!
		}
	}
}

// Resets the cache for the current Git structure, removing cached data from Redis.
pub fn (mut gitstructure GitStructure) cachereset() ! {
	mut redis := redis_get()
	keys := redis.keys('git:repos:${gitstructure.key}:**')!

	for key in keys {
		redis.del(key)!
	}
}

@[params]
pub struct RepoInitParams {
	ssh_key_name string // name of ssh key to be used in repo
}

// Initializes a Git repository from a given path by locating the parent directory with `.git`.
//
// Args:
// - path (string): Path to initialize the repository from.
//
// Returns:
// - GitRepo: Reference to the initialized repository.
//
// Raises:
// - Error: If `.git` is not found in the parent directories.
fn (mut gitstructure GitStructure) repo_init_from_path_(path string, params RepoInitParams) !GitRepo {
	mypath := pathlib.get_dir(path: path, create: false)!
	mut parent_path := mypath.parent_find('.git') or {
		return error('Cannot find .git in parent directories starting from: ${path}')
	}

	if parent_path.path == '' {
		return error('Cannot find .git in parent directories starting from: ${path}')
	}

	// Retrieve GitLocation from the path.
	gl := gitstructure.gitlocation_from_path(mypath.path)!

	// Initialize and return a GitRepo struct.
	mut r := GitRepo{
		gs:            &gitstructure
		status_remote: GitRepoStatusRemote{}
		status_local:  GitRepoStatusLocal{}
		config:        GitRepoConfig{}
		provider:      gl.provider
		account:       gl.account
		name:          gl.name
		deploysshkey:  params.ssh_key_name
	}

	return r
}

// returns the git repository of the working directory by locating the parent directory with `.git`.
//
// Returns:
// - GitRepo: Reference to the initialized repository.
//
// Raises:
// - None: If `.git` is not found in the parent directories.
pub fn (mut gitstructure GitStructure) get_working_repo() ?GitRepo {
	curdir := pathlib.get_wd()
	return gitstructure.repo_init_from_path_(curdir.path) or { return none }
}
