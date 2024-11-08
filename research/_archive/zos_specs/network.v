module zos

import time

struct NetworkCreateParams {
	name                  string // network name
	description           string // network description
	ip_range              string // network ip range
	subnet                IPNet  // network subnet
	wireguard_private_key string // network private key
	wireguard_listen_port u16    // network listen port
	peers                 []Peer // ["network list of peers"]
}

pub fn (client ZOSClient) zos_deployment_network_create(params NetworkCreateParams) {
}

struct NetworkUpdateParams {
	deployment_name       string // deployment name
	name                  string // network name
	version               u32    // deployment version
	description           string // network description
	metadata              string // network metadata (UserAccessIP, PrivateKey, PublicNodeID)
	ip_range              string // network ip range
	subnet                IPNet  // network subnet
	wireguard_private_key string // network private key
	wireguard_listen_port u16    // network listen port
	peers                 []Peer // ["network list of peers"]
}

pub fn (client ZOSClient) zos_deployment_network_update(params NetworkUpdateParams) {
}

struct NetworkGetParams {
	deployment_name string // deployment name
	name            string // network name
}

pub fn (client ZOSClient) zos_deployment_network_get(params NetworkGetParams) {
}

struct NetworkDeleteParams {
	deployment_name string // deployment name
	name            string // network name
}

pub fn (client ZOSClient) zos_deployment_network_delete(params NetworkDeleteParams) {
}
