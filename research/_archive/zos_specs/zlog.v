module zos

struct ZlogParams {
	deployment_name string // deployment name
	name            string // zlog name
	version         u32    // deployment version
	vm_name         string // vm name
	output          string // zlog output
}

pub fn (client ZOSClient) zos_deployment_zlog_create(params ZlogParams) {
}

pub fn (client ZOSClient) zos_deployment_zlog_update(params ZlogParams) {
}

struct ZlogGetParams {
	deployment_name string // deployment name
	name            string // zlog name
}

pub fn (client ZOSClient) zos_deployment_zlog_get(params ZlogGetParams) {
}

struct ZlogDeleteParams {
	deployment_name string // deployment name
	name            string // zlog name
}

pub fn (client ZOSClient) zos_deployment_zlog_delete(params ZlogDeleteParams) {
}
