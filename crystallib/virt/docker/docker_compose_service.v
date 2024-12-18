module docker

import v.embed_file
import freeflowuniverse.crystallib.data.paramsparser { Params }

@[heap]
pub struct ComposeService {
pub mut:
	name    string
	content string // optional
	params  Params
	files   []embed_file.EmbedFileData
	recipe  &DockerComposeRecipe @[str: skip]
	render  bool = true
	env     map[string]string
	ports   []PortMap
	volumes []VolumeMap
	restart bool
	image   string
}

pub struct PortMap {
pub:
	indocker int
	host     int
}

pub struct VolumeMap {
pub:
	hostpath      string
	containerpath string
}

@[params]
pub struct ComposeServiceArgs {
pub:
	name    string @[required]
	image   string @[required]
	params  string
	content string // optional, if this is set then will not render
}

pub fn (mut recipe DockerComposeRecipe) service_new(args ComposeServiceArgs) !&ComposeService {
	if args.name == '' {
		return error('name cannot be empty.')
	}
	mut cs := ComposeService{
		recipe:  &recipe
		name:    args.name
		content: args.content
		image:   args.image
	}
	if args.content.len > 0 {
		cs.render = false
	}
	recipe.items << &cs
	return recipe.items.last()
}

// example:
// registry:
//   restart: always
//   image: registry:2
//   ports:
//     - 5000:5000
//   environment:
//     REGISTRY_HTTP_TLS_CERTIFICATE: /certs/domain.crt
//     REGISTRY_HTTP_TLS_KEY: /certs/domain.key
//     REGISTRY_AUTH: htpasswd
//     REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
//     REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
//   volumes:
//     - ${registry.datapath}/data:/var/lib/registry
//     - ${registry.datapath}/certs:/certs
//     - ${registry.datapath}/auth:/auth

// render the recipe to a compose file
fn (mut b ComposeService) render() !string {
	mut out := '${b.name}:\n'
	if b.render == false {
		return b.content
	}
	out += '  image: ${b.image}\n'
	if b.restart {
		out += '  restart: always\n'
	}
	if b.ports.len > 0 {
		out += '  ports:\n'
		for port in b.ports {
			out += '    - ${port.indocker}:${port.host}\n'
		}
	}
	if b.env.len > 0 {
		out += '  environment:\n'
		for ekey, eval in b.env {
			out += '    ${ekey.to_upper()}: ${eval}\n'
		}
	}
	if b.volumes.len > 0 {
		out += '  volumes:\n'
		for volitem in b.volumes {
			out += '    - ${volitem.hostpath}:${volitem.containerpath}\n'
		}
	}
	b.content = out
	return out
}

// add an environment variable to the service
pub fn (mut cs ComposeService) env_add(key string, val string) {
	cs.env[key] = val
}

// make sure the service always restarts
pub fn (mut cs ComposeService) restart_set() {
	cs.restart = true
}

// make sure the service always restarts
pub fn (mut cs ComposeService) port_expose(indocker int, host int) ! {
	// TODO: should check if hostport is free
	mp := PortMap{
		indocker: indocker
		host:     host
	}
	cs.ports << mp
}

// make sure the service always restarts
pub fn (mut cs ComposeService) volume_add(hostpath string, containerpath string) ! {
	mut vm := VolumeMap{
		hostpath:      hostpath
		containerpath: containerpath
	}
	vm.check()!
	cs.volumes << vm
}

pub fn (mut vm VolumeMap) check() ! {
	// TODO: see if it exists on remote host
}
