module zdb

type ZDBMode = string

struct ZDBGroup {
	backends []ZDBBackend
}

struct ZDBBackend {
	address   string
	namespace string
	password  string
}

struct ZdbCreateParams {
	deployment_name string  // deployment name
	name            string  // zdb name
	version         u32     // deployment version
	mode            ZDBMode // zdb mode
	size            Unit    // zdb size in GB
	password        string  //
	public          bool    // if zdb gets a public ip6
}

pub fn (client ZOSClient) zos_deployment_zdb_create(params ZdbCreateParams) {
}

struct ZdbUpdateParams {
	deployment_name string  // deployment name
	name            string  // zdb name
	version         u32     // deployment version
	mode            ZDBMode // zdb mode
	size            Unit    // zdb size in GB
	password        string  //
	public          bool    // if zdb gets a public ip6
}

pub fn (client ZOSClient) zos_deployment_zdb_update(params ZdbUpdateParams) {
}

struct ZdbGetParams {
	deployment_name string // deployment name
	name            string // zdb name
}

pub fn (client ZOSClient) zos_deployment_zdb_get(params ZdbGetParams) {
}

struct ZdbDeleteParams {
	deployment_name string // deployment name
	name            string // zdb name
}

pub fn (client ZOSClient) zos_deployment_zdb_delete(params ZdbDeleteParams) {
}
