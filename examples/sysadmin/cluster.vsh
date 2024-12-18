#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.sysadmin.cluster
import freeflowuniverse.crystallib.core.playbook

pub fn play(mut plbook playbook.PlayBook) ! {
	mut cl := cluster.new()

	mut actions_cluster_define := plbook.find(filter: 'cluster.define')!

	for action in actions_cluster_define {
		mut p := action.params
		cl.name = p.get_default('name', 'my_cluster')!
		cl.active = p.get_default_true('active')
		cl.secret = p.get('secret')!
	}

	if cl.name == '' {
		return error('we need 1 cluster defined')
	}

	// now we have the cluster

	mut actions_add_node := plbook.find(filter: 'cluster.add_node')!

	for action in actions_add_node {
		mut p := action.params
		mut n := cluster.Node{
			nr:          p.get_int('nr')!
			name:        p.get_default('name', 'node1')!
			description: p.get_default('description', '')!
			ipaddress:   p.get('ipaddress')!
			active:      p.get_default_true('active')
		}
		cl.nodes << n
	}

	mut actions_add_admin := plbook.find(filter: 'cluster.add_admin')!

	for action in actions_add_admin {
		mut p := action.params
		mut a := cluster.Admin{
			name:        p.get_default('name', 'admin1')!
			description: p.get_default('description', '')!
			ipaddress:   p.get('ipaddress')!
			active:      p.get_default_true('active')
		}
		cl.admins << a
	}

	mut actions_add_service := plbook.find(filter: 'cluster.add_service')!

	for action in actions_add_service {
		mut p := action.params
		mut s := cluster.Service{
			name:        p.get('name')!
			description: p.get_default('description', '')!
			port:        p.get_list_int_default('port', [])
			port_public: p.get_list_int_default('port_public', [])
			active:      p.get_default_true('active')
			installer:   p.get_default('installer', '')!
			depends:     p.get_list_namefix_default('depends', [])!
			nodes:       p.get_list_int_default('nodes', [])
		}
		if p.exists('master') {
			s.master = p.get_int('master')!
		}

		cl.services << s
	}

	cl.check()!

	println(cl)
}

heroscript := "
!!cluster.define
    name: 'my_cluster'
    active: true
	secret: 'PlanetFirst7'

!!cluster.add_node
    nr: 1
    name: 'node1'
    description: 'First node in the cluster'
    ipaddress: '192.168.1.10'
    active: true

!!cluster.add_node
    nr: 2
    name: 'node2'
    description: 'Second node in the cluster'
    ipaddress: '192.168.1.11'
    active: true

!!cluster.add_admin
    name: 'admin1'
    description: 'Main cluster administrator'
    ipaddress: '192.168.1.100'
    active: true

!!cluster.add_service
    name: 'web_service'
    description: 'Main web service'
    port_public: '443'
    active: true
    installer: 'caddy'
    depends: 'database_service'
    nodes: '1,2'
    master: 1

!!cluster.add_service
    name: 'database_service'
    description: 'Database service'
    port: 5432
    installer: 'postgresql'
    nodes: 2


"

// see freeflowuniverse.crystallib.sysadmin.cluster for the model description

mut plbook := playbook.new(text: heroscript)!
play(mut plbook)!
