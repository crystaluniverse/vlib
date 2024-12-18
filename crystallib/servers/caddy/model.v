module caddy

import net.urllib
import freeflowuniverse.crystallib.servers.caddy.security
import freeflowuniverse.crystallib.servers.caddy.http

pub struct CaddyFile {
pub mut:
	admin AdminConfig @[omitempty]
	apps  Apps        @[omitempty]
}

pub struct Address {
pub mut:
	url         urllib.URL @[omitempty]
	description string     @[omitempty]
}

pub struct AdminConfig {
pub mut:
	disabled       bool           @[omitempty]
	listen         string         @[omitempty]
	enforce_origin bool           @[omitempty]
	origins        []string       @[omitempty]
	config         ConfigSettings @[omitempty]
	identity       IdentityConfig @[omitempty]
	remote         RemoteAdmin    @[omitempty]
}

struct ConfigSettings {
	persist bool @[omitempty]
	load    LoadConfig
}

struct LoadConfig {
	// Add appropriate fields for load config
}

struct IdentityConfig {
	identifiers []string
	issuers     []IssuerConfig
}

struct IssuerConfig {
	// Add appropriate fields for issuer config
}

struct RemoteAdmin {
	listen         string
	access_control []AdminAccess
}

struct AdminAccess {
	public_keys []string
	permissions []AdminPermissions
}

struct AdminPermissions {
	paths   []string
	methods []string
}

struct LoggingConfig {
	sink SinkConfig
	logs map[string]CustomLog
}

struct SinkConfig {
	writer WriterConfig
}

struct WriterConfig {
	// Add appropriate fields for writer config
}

struct CustomLog {
	writer   WriterConfig  @[omitempty]
	encoder  EncoderConfig @[omitempty]
	level    string
	sampling LogSampling @[omitempty]
	include  []string    @[omitempty]
	exclude  []string    @[omitempty]
}

struct EncoderConfig {
	// Add appropriate fields for encoder config
}

struct LogSampling {
	interval   int
	first      int
	thereafter int
}

pub struct Apps {
pub mut:
	security security.Security
	http     http.HTTP
}
