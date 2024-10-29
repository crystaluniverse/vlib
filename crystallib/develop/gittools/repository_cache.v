module gittools

import freeflowuniverse.crystallib.core.base
import json

// Save repo to redis cache
fn (repo GitRepo) cache_set() ! {
	mut context := base.context()!
	mut redis := context.redis()!
	repo_json := json.encode(repo)
	cache_key := repo.get_cache_key()
	redis.set(cache_key, repo_json)!
}

// Get repo from redis cache
fn (mut repo GitRepo) cache_get() ! {
	mut context := base.context()!
	mut redis := context.redis()!
	cache_key := repo.get_cache_key()
	repo_json := redis.get(cache_key)!
	if repo_json.len > 0 {
		mut cached := json.decode(GitRepo, repo_json)!
		cached.gs = repo.gs
		repo = cached
	}
}

// Remove cache
fn (repo GitRepo) cache_delete() ! {
	mut context := base.context() or { return error('Cannot get the context due to: ${err}') }
	mut redis := context.redis() or { return error('Cannot get redis due to: ${err}') }
	cache_key := repo.get_cache_key()
	redis.del(cache_key) or { return error('Cannot delete the repo cache due to: ${err}') }
}
