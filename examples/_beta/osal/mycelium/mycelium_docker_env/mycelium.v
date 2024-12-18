module main

import freeflowuniverse.crystallib.virt.docker
import freeflowuniverse.crystallib.osal { exec }
import os

const keypath_in_container = '/etc/mycelium_key.bin'

fn do() ! {
	dockerregistry_datapath := ''
	// dockerregistry_datapath:="/Volumes/FAST/DOCKERHUB"
	// prefix:="despiegk/" //dont forget trailing slash
	prefix := ''
	localonly := false

	mut engine := docker.new(prefix: prefix, localonly: localonly)!

	if dockerregistry_datapath.len > 0 {
		engine.registry_add(datapath: dockerregistry_datapath)! // this means we run one locally
	}
	pwd := os.getwd()
	// forwarding the ssh port is a workaround for https://github.com/freeflowuniverse/crystallib/issues/206

	mut name := 'mycelium_1'
	mut keypath := os.join_path(pwd, 'keys', name + '_key.bin')
	engine.container_create(
		name:            name
		hostname:        name
		privileged:      true
		image_repo:      'mycelium'
		command:         ''
		forwarded_ports: ['20001:22']
		mounted_volumes: ['${keypath}:${keypath_in_container}']
	)!
	first_container_ip := get_ipaddress(name)!
	println('Started container ${name} with ip ${first_container_ip}')

	name = 'mycelium_2'
	keypath = os.join_path(pwd, 'keys', name + '_key.bin')
	engine.container_create(
		name:            name
		hostname:        name
		privileged:      true
		image_repo:      'mycelium'
		command:         ''
		forwarded_ports: ['20002:22']
		mounted_volumes: ['${keypath}:${keypath_in_container}']
	)!
	println('Started container ${name}')

	name = 'mycelium_3'
	keypath = os.join_path(pwd, 'keys', name + '_key.bin')
	engine.container_create(
		name:            name
		hostname:        name
		privileged:      true
		image_repo:      'mycelium'
		command:         ''
		forwarded_ports: ['20003:22']
		mounted_volumes: ['${keypath}:${keypath_in_container}']
	)!
	println('Started container ${name}')

	// Not using engine.container_get or the returned containers from the container_create methods
	// as there is something wrong with the references, the wrong one get's returned ( issue #210 ) and acessing it segfaults

	// Start mycelium in all containers, use container 1 has hop
	execute_in_container('mycelium_1', 'mycelium -k ${keypath_in_container}')!
	execute_in_container('mycelium_2', 'mycelium -k ${keypath_in_container} --peers ${first_container_ip}:9651')!
	execute_in_container('mycelium_3', 'mycelium -k ${keypath_in_container} --peers ${first_container_ip}:9651')!
}

pub fn get_ipaddress(container_name string) !string {
	mut ljob := exec(
		cmd:    "docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${container_name}"
		stdout: false
	)!
	lines := ljob.output
	for line in lines {
		if line.trim_space() == '' {
			continue
		}
		return line
	}
	return ''
}

pub fn execute_in_container(container string, cmd_ string) ! {
	// mycelium requires a terminal ( issue #17 )
	cmd := 'docker exec -t -d ${container} ${cmd_}'
	exec(cmd: cmd, stdout: false)!
}

fn main() {
	do() or { panic(err) }
}
