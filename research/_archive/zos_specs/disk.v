module zos

import time

struct DiskCreateParams {
	deployment_name string // deployment name
	name            string // disk name
	version         u32    // deployment version
	description     string // disk description
	size            Unit   // disk size
}

pub fn (client ZOSClient) zos_deployment_disk_create(params DiskCreateParams) {
}

struct DiskUpdateParams {
	deployment_name string // deployment name
	name            string // disk name
	version         u32    // deployment version
	description     string // disk description
	size            Unit   // disk size
}

pub fn (client ZOSClient) zos_deployment_disk_update(params DiskUpdateParams) {
}

struct DiskGetParams {
	deployment_name string // deployment name
	name            string // disk name
}

pub fn (client ZOSClient) zos_deployment_disk_get(params DiskGetParams) {
}

struct DiskDeleteParams {
	deployment_name string // deployment name
	name            string // disk name
}

pub fn (client ZOSClient) zos_deployment_disk_delete(params DiskDeleteParams) {
}
