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
