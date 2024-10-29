module gittools

import freeflowuniverse.crystallib.core.pathlib

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
import os

// GitStructureConfig defines configuration settings for a GitStructure instance.
@[params]
pub struct GitStructureConfig {
pub mut:
	coderoot string // Root directory where code is checked out, comes from context if not specified
	light    bool = true // If true, clones only the last history for all branches (clone with only 1 level deep)
	log      bool = true // If true, logs git commands/statements
	debug    bool = true
}

// GitStructure holds information about repositories within a specific code root.
// This structure keeps track of loaded repositories, their configurations, and their status.
@[heap]
pub struct GitStructure {
pub mut:
	key      string                // Unique key representing the git structure (default is hash of $home/code).
	config   GitStructureConfig    // Configuration settings for the git structure.
	coderoot pathlib.Path          // Root directory where repositories are located.
	repos    map[string]&GitRepo   // Map of repositories, keyed by their unique names.
	loaded   bool                  // Indicates if the repositories have been loaded into memory.
}


//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////


@[params]
pub struct StatusUpdateArgs {
	reload bool
}

// Loads all repository information from the filesystem and updates from remote if necessary.
// Use the reload argument to force reloading from the disk.
//
// Args:
// - args (StatusUpdateArgs): Arguments controlling the reload behavior.
pub fn (mut gitstructure GitStructure) load(args StatusUpdateArgs) ! {
	mut processed_paths := []string{}
	gitstructure.load_recursive(gitstructure.coderoot.path, args, mut processed_paths)!
	gitstructure.init()!
}

//just some initialization mechanism
pub fn (mut gitstructure GitStructure) init() ! {
	if gitstructure.config.debug{
		gitstructure.config.log = true
	}
}


// Recursively loads repositories from the provided path, updating their statuses.
//
// Args:
// - path (string): The path to search for repositories.
// - args (StatusUpdateArgs): Controls the status update and reload behavior.
// - processed_paths ([]string): List of already processed paths to avoid duplication.
fn (mut gitstructure GitStructure) load_recursive(path string, args StatusUpdateArgs, mut processed_paths []string) ! {
	console.print_debug('Recursively loading gitstructure from: ${path}')

	path_object := pathlib.get(path)
	relpath := path_object.path_relative(gitstructure.coderoot.path)!

	// Limit the recursion depth to avoid deep directory traversal.
	if relpath.count('/') > 4 {
		return
	}

	items := os.ls(path) or { return error('Cannot load gitstructure because directory not found: ${path}') }

	for item in items {
		current_path := os.join_path(path, item)

		if os.is_dir(current_path) {
			if os.exists(os.join_path(current_path, '.git')) {
				// Initialize the repository from the current path.
				mut repo := gitstructure.repo_init_from_path_(current_path)!
				repo.status_update()!

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
			gitstructure.load_recursive(current_path, args, mut processed_paths)!
		}
	}
}

// Resets the cache for the current Git structure, removing cached data from Redis.
pub fn (mut gitstructure GitStructure) cachereset() ! {
	mut context := base.context()!
	mut redis := context.redis()!
	keys := redis.keys('git:repos:${gitstructure.key}:**')!

	for key in keys {
		redis.del(key)!
	}
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
fn (mut gitstructure GitStructure) repo_init_from_path_(path string) !GitRepo {
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
	mut r:= GitRepo{
		gs:            &gitstructure
		status_remote: GitRepoStatusRemote{}
		status_local:  GitRepoStatusLocal{}
		config:        GitRepoConfig{}
		provider:      gl.provider
		account:       gl.account
		name:          gl.name
	}
	r.status_update()!
	return r
}

