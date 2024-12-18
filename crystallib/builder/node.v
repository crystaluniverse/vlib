module builder

import json
import freeflowuniverse.crystallib.data.paramsparser { Params }
import freeflowuniverse.crystallib.core.base
// import freeflowuniverse.crystallib.ui.console
import crypto.md5

pub enum PlatformType {
	unknown
	osx
	ubuntu
	alpine
	arch
}

pub enum CPUType {
	unknown
	intel
	arm
	intel32
	arm32
}

@[heap]
pub struct Node {
mut:
	factory &BuilderFactory @[skip; str: skip]
pub mut:
	name        string = 'unknown'
	executor    Executor @[skip; str: skip]
	platform    PlatformType
	cputype     CPUType
	done        map[string]string
	environment map[string]string
	params      Params
	hostname    string
}

// get unique key for the node, as used in caching environment
pub fn (mut node Node) key() string {
	mut myhash := 'local'
	if mut node.executor is ExecutorSSH {
		myaddr := node.executor.ipaddr.address() or { panic(err) }
		myhash = md5.hexhash(myaddr)
	}
	return node.name + '_' + myhash
}

// get remote environment arguments in memory
pub fn (mut node Node) readfromsystem() ! {
	node.platform_load()!
	node.environment = node.environ_get(reload: true) or {
		return error('can not load env.\n ${err}')
	}

	home := node.environment['HOME'] or {
		return error('could not find HOME in environment variables.\n ${node}')
	}
	node.environment['HOME'] = home.trim_space()
	if node.environment['HOME'] == '' {
		return error('HOME env cannot be empty for ${node.name}')
	}
	node.save()!
}

// load the node from redis cache, if not there will load from system .
// return true if the data was in redis (cache)
pub fn (mut node Node) load() !bool {
	mut mycontext := base.context()!
	mut r := mycontext.redis()!
	data := r.hget('nodes', node.key())!
	if data == '' {
		node.readfromsystem()!
		return false
	}
	data2 := json.decode(Node, data)!

	node.platform = data2.platform
	node.cputype = data2.cputype
	node.done = data2.done.clone()
	node.environment = data2.environment.clone()
	node.params = data2.params
	if node.environment.len == 0 {
		node.readfromsystem()!
		node.save()!
	}
	return true
}

// get remote environment arguments in memory
pub fn (mut node Node) save() ! {
	data := json.encode(node)
	mut mycontext := base.context()!
	mut r := mycontext.redis()!
	r.hset('nodes', node.key(), data)!
}
