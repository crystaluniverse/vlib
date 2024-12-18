module zerohub

import net.http

// import freeflowuniverse.crystallib.clients.httpconnection

// TODO: curl -H "Authorization: bearer 6Pz6giOpHSaA3KdYI6LLpGSLmDmzmRkVdwvc7S-E5PVB0-iRfgDKW9Rb_ZTlj-xEW4_uSCa5VsyoRsML7DunA1sia3Jpc3RvZi4zYm90IiwgMTY3OTIxNTc3MF0=" https://hub.grid.tf/api/flist/

pub struct ZeroHubClient {
pub mut:
	url    string
	secret string // is called bearer in documentation	
	header http.Header
}

@[params]
pub struct ZeroHubClientArgs {
pub:
	url    string = 'hub.grid.tf'
	secret string // is called bearer in documentation	
}

// see https://hub.grid.tf/
// more info see https://github.com/threefoldtech/0-hub#public-api-endpoints-no-authentication-needed
pub fn new(args ZeroHubClientArgs) !ZeroHubClient {
	// mut conn := httpconnection.new(name:'zerohub', url:'https://${args.url}')	

	// TODO: use our caching rest client (httpclient)
	// example which was working: curl -H "Authorization: bearer ""..." https://hub.grid.tf/api/flist/
	// see how to get this Authorization bearer to work with our httpclient, certain header to be set.
	// if args.reset {
	// 	//if reset asked for cache will be emptied
	// 	conn.cache.cache_drop()!
	// }

	mut cl := ZeroHubClient{
		url:    args.url
		secret: args.secret
	}
	// TODO: there should be a check here that its accessible
	return cl
}
