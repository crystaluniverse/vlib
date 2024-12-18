#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.virt.docker
import os

registration_code := os.getenv('PRESEARCH_CODE')

if registration_code == '' {
	println("Can't find presearch registration code please run 'export PRESEARCH_CODE=...'")
	exit(1)
}

mut engine := docker.new(prefix: '', localonly: true)!
mut recipe := engine.compose_new(name: 'presearch')
mut presearch_node := recipe.service_new(name: 'presearch_node', image: 'presearch/node')!

presearch_node.volume_add('/presearch-node-storage', '/app/node')!
presearch_node.env_add('REGISTRATION_CODE', '${registration_code}')

mut presearch_updater := recipe.service_new(
	name:  'presearch_updater'
	image: 'presearch/auto-updater'
)!
presearch_updater.volume_add('/var/run/docker.sock', '/var/run/docker.sock')!

recipe.start()!
