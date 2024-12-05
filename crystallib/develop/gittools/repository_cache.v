module gittools

import json
import freeflowuniverse.crystallib.clients.redisclient

fn redis_get() redisclient.Redis{	
	mut redis_client := redisclient.core_get() or { panic(err) }
	return redis_client
}


// Save repo to redis cache
fn (mut repo GitRepo) cache_set() ! {
	mut redis_client := redis_get()
	repo_json := json.encode(repo)
	cache_key := repo.get_cache_key()
	redis_client.set(cache_key, repo_json)!
}

// Get repo from redis cache
fn (mut repo GitRepo) cache_get() ! {
	mut repo_json := ''
	mut redis_client := redis_get()
	cache_key := repo.get_cache_key()
	repo_json = redis_client.get(cache_key)!

	if repo_json.len > 0 {
		mut cached := json.decode(GitRepo, repo_json)!
		cached.gs = repo.gs
		repo = cached
	}
}

// Remove cache
fn (repo GitRepo) cache_delete() ! {
	mut redis_client := redis_get()
	cache_key := repo.get_cache_key()
	redis_client.del(cache_key) or {
		return error('Cannot delete the repo cache due to: ${err}')
	}
	// TODO: report v bug, function should work without return as well
	return
}
