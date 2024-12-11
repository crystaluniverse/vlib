module gittools

import os
import json
import freeflowuniverse.crystallib.core.pathlib

__global (
	gsinstances map[string]&GitStructure
)

pub fn reset() {
	gsinstances = map[string]&GitStructure{} // they key is the redis_key (hash of coderoot)
}

@[params]
pub struct GitStructureArgsNew {
pub mut:
	coderoot     string
	light        bool = true // If true, clones only the last history for all branches (clone with only 1 level deep)
	log          bool = true // If true, logs git commands/statements
	debug        bool = true
	ssh_key_name string // name of ssh key to be used when loading the gitstructure
	reload       bool
}

// Retrieve or create a new GitStructure instance with the given configuration.
pub fn new(args_ GitStructureArgsNew) !&GitStructure {
	mut args := args_
	if args.coderoot == '' {
		args.coderoot = '${os.home_dir()}/code'
	}
	mut cfg := GitStructureConfig{
		coderoot:     args.coderoot
		light:        args.light
		log:          args.log
		debug:        args.debug
		ssh_key_name: args.ssh_key_name
	}
	// Retrieve the configuration from Redis.
	rediskey_ := rediskey(args.coderoot)
	mut redis := redis_get()
	datajson := json.encode(cfg)
	redis.set(rediskey_, datajson)!

	return get(coderoot: args.coderoot, reload: args.reload)
}

@[params]
pub struct GitStructureArgGet {
pub mut:
	coderoot string
	reload   bool
}

// Retrieve a GitStructure instance based on the given arguments.
pub fn get(args_ GitStructureArgGet) !&GitStructure {
	mut args := args_
	if args.coderoot == '' {
		args.coderoot = '${os.home_dir()}/code'
	}
	if args.reload {
		cachereset()!
	}
	rediskey_ := rediskey(args.coderoot)
	// println(rediskey_)

	// Return existing instance if already created.
	if rediskey_ in gsinstances {
		mut gs := gsinstances[rediskey_] or {
			panic('Unexpected error: key not found in gsinstances')
		}
		if args.reload {
			gs.load()!
		}
		return gs
	}

	mut redis := redis_get()
	mut datajson := redis.get(rediskey_) or { '' }

	if datajson == '' {
		if args_.coderoot == '' {
			return new()!
		}
		return error("can't find repostructure for coderoot: ${args.coderoot}")
	}

	mut config := json.decode(GitStructureConfig, datajson) or { GitStructureConfig{} }

	// Create and load the GitStructure instance.
	mut gs := GitStructure{
		key:      rediskey_
		config:   config
		coderoot: pathlib.get_dir(path: args.coderoot, create: true)!
	}

	if args.reload {
		gs.load()!
	} else {
		gs.init()!
	}

	gsinstances[rediskey_] = &gs

	return gsinstances[rediskey_] or { panic('bug') }
}

// Reset the configuration cache for Git structures.
pub fn configreset() ! {
	mut redis := redis_get()
	key_check := 'git:config:*'
	keys := redis.keys(key_check)!

	for key in keys {
		redis.del(key)!
	}
}

// Reset all caches and configurations for all Git repositories.
pub fn cachereset() ! {
	key_check := 'git:repos:**'
	mut redis := redis_get()
	keys := redis.keys(key_check)!

	for key in keys {
		redis.del(key)!
	}
	configreset()!
}
