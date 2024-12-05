module gittools

import json

// Save repo to redis cache
fn (mut repo GitRepo) cache_set() ! {
	lock redis_client {
		repo_json := json.encode(repo)
		cache_key := repo.get_cache_key()
		redis_client.set(cache_key, repo_json)!
	}
}

// Get repo from redis cache
fn (mut repo GitRepo) cache_get() ! {
	mut repo_json := ''
	lock redis_client {
		cache_key := repo.get_cache_key()
		repo_json = redis_client.get(cache_key)!
	}

	if repo_json.len > 0 {
		mut cached := json.decode(GitRepo, repo_json)!
		cached.gs = repo.gs
		repo = cached
	}
}

// Remove cache
fn (repo GitRepo) cache_delete() ! {
	lock redis_client {
		cache_key := repo.get_cache_key()
		redis_client.del(cache_key) or {
			return error('Cannot delete the repo cache due to: ${err}')
		}
		// TODO: report v bug, function should work without return as well
		return
	}
}
