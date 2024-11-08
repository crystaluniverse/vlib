module zos

import time
import freeflowuniverse.crystallib.data.ipaddress

struct VmCreateParams {
	deployment_name string   // deployment name
	name            string   // vm name
	version         u32      // deployment version
	description     string   // vm description
	flist           string   // vm flist
	network         string   // vm network
	size            Unit     // disk size in GB
	capacity        Capacity // cpu and memory
	mounts          []Mount  // [{"name":"mount name","point":"mount point"}]
	entrypoint      string   // vm entry point
	env             map[string]string // {"key":"value"}
	corex           bool  // vm corex
	gpus            []GPU // ["vm list of gpus"]
}

pub fn (client ZOSClient) zos_deployment_vm_create(params VmCreateParams) {
}

struct VmUpdateParams {
	deployment_name string   // deployment name
	name            string   // vm name
	version         u32      // deployment version
	description     string   // vm description
	flist           string   // vm flist
	network         string   // vm network
	size            Unit     // disk size in GB
	capacity        Capacity // cpu and memory
	mounts          []Mount  // [{"name":"mount name","point":"mount point"}]
	entrypoint      string   // vm entry point
	env             map[string]string // {"key":"value"}
	corex           bool  // vm corex
	gpus            []GPU // ["vm list of gpus"]
}

pub fn (client ZOSClient) zos_deployment_vm_update(params VmUpdateParams) {
}

struct VmGetParams {
	deployment_name string // deployment name
	name            string // vm name
}

pub fn (client ZOSClient) zos_deployment_vm_get(params VmGetParams) {
}

struct VmDeleteParams {
	deployment_name string // deployment name
	name            string // vm name
}

pub fn (client ZOSClient) zos_deployment_vm_delete(params VmDeleteParams) {
}

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

struct QsfsParams {
	deployment_name       string             // deployment name
	name                  string             // qsfs name
	version               u32                // deployment version
	cache                 Unit               // qsfs cache
	minimal_shards        u32                // qsfs minimal shards
	expected_shards       u32                // qsfs expected shards
	redundant_groups      u32                // qsfs redundant groups
	redundant_nodes       u32                // qsfs redundant nodes
	max_zdb_data_dir_size u32                // qsfs max zdb data dir size
	encryption            Encryption         // qsfs encryption
	metadata              QuantumSafeMeta    // qsfs metadata
	groups                []ZDBGroup         // qsfs groups
	compression           QuantumCompression // qsfs compression
}

pub fn (client ZOSClient) zos_deployment_qsfs_create(params QsfsParams) {
}

pub fn (client ZOSClient) zos_deployment_qsfs_update(params QsfsParams) {
}

struct QsfsGetParams {
	deployment_name string // deployment name
	name            string // qsfs name
}

pub fn (client ZOSClient) zos_deployment_qsfs_get(params QsfsGetParams) {
}

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

struct GatewayFqdnParams {
	deployment_name string    // deployment name
	name            string    // gateway name
	version         string    // deployment version
	fqdn            string    // fqdn
	tls_passthrough string    // tls passthrough is optional
	network         string    // gateway network
	backends        []Backend // ["list of backends"]
}

pub fn (client ZOSClient) zos_deployment_gateway_fqdn_create(params GatewayFqdnParams) {
}

pub fn (client ZOSClient) zos_deployment_gateway_fqdn_update(params GatewayFqdnParams) {
}

struct GatewayFqdnGetParams {
	deployment_name string // deployment name
	name            string // gateway name
}

pub fn (client ZOSClient) zos_deployment_gateway_fqdn_get(params GatewayFqdnGetParams) {
}

struct GatewayNameParams {
	deployment_name string    // deployment name
	name            string    // gateway name
	version         u32       // deployment version
	tls_passthrough bool      // tls passthrough is optional
	network         string    // gateway network
	backends        []Backend // ["list of backends"]
}

pub fn (client ZOSClient) zos_deployment_gateway_name_create(params GatewayNameParams) {
}

type Backend = string

pub fn (client ZOSClient) zos_deployment_gateway_name_update(params GatewayNameParams) {
}

struct GatewayNameGetParams {
	deployment_name string // deployment name
	name            string // gateway name
}

pub fn (client ZOSClient) zos_deployment_gateway_name_get(params GatewayNameGetParams) {
}

struct PublicIpParams {
	deployment_name string // deployment name
	name            string // public_ip name
	version         u32    // deployment version
	ipv4            bool   // if you want an ipv4
	ipv6            bool   // if you want an ipv6
}

pub fn (client ZOSClient) zos_deployment_public_ip_create(params PublicIpParams) {
}

pub fn (client ZOSClient) zos_deployment_public_ip_update(params PublicIpParams) {
}

struct PublicIpGetParams {
	deployment_name string // deployment name
	name            string // public_ip name
}

pub fn (client ZOSClient) zos_deployment_public_ip_get(params PublicIpGetParams) {
}

struct PublicIpDeleteParams {
	deployment_name string // deployment name
	name            string // public_ip name
}

pub fn (client ZOSClient) zos_deployment_public_ip_delete(params PublicIpDeleteParams) {
}
