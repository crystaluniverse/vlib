module http

// HTTP represents the main HTTP configuration, containing a map of servers.
pub struct HTTP {
pub mut:
	servers map[string]Server @[omitempty]
}

// Server represents a single HTTP server with listening ports and routes.
pub struct Server {
pub mut:
	listen []string = [':443'] // Ports the server listens on
	routes []Route @[omitempty]
}

// Route defines an HTTP route with match conditions and handlers.
pub struct Route {
pub mut:
	@match   []Match  @[omitempty]
	handle   []Handle @[omitempty]
	terminal bool = true // Determines if this route is terminal
}

// Match specifies the matching conditions for routes based on host and path.
pub struct Match {
pub mut:
	host []string @[omitempty] // Hostnames to match
	path []string @[omitempty] // Paths to match
}

// Handle defines the actions to be performed for matched routes.
pub struct Handle {
pub mut:
	handler       string // Type of handler
	routes        []Route             @[omitempty] // Nested routes
	providers     Providers           @[omitempty] // Authentication providers
	root          string              @[omitempty] // Root directory for file server
	hide          []string            @[omitempty] // Paths to hide
	upstreams     []map[string]string @[omitempty] // Upstream servers for reverse proxy
	portal_name   string              @[omitempty] // Portal name for authentication
	route_matcher string              @[omitempty] // Route matcher for authentication
	body          string              @[omitempty] // Body content
	status_code   int                 @[omitempty] // Status code for response
}

// Providers contains different authentication providers.
pub struct Providers {
pub mut:
	authorizer Authorizer @[omitempty]
	http_basic HTTPBasic  @[omitempty]
}

// HTTPBasic represents the basic HTTP authentication provider.
pub struct HTTPBasic {
pub mut:
	hash       Hash
	accounts   []Account         // List of accounts for basic auth
	hash_cache map[string]string // Cache for hashed passwords
}

// Authorizer defines the authorizer for authentication.
pub struct Authorizer {
pub:
	gatekeeper_name string // Name of the gatekeeper
	route_matcher   string // Route matcher for the authorizer
}

// Hash specifies the hashing algorithm used for passwords.
pub struct Hash {
pub:
	algorithm string // Hashing algorithm
}

// Account represents a user account for basic authentication.
pub struct Account {
pub:
	username string // Username for the account
	password string // Password for the account (hashed)
}
