module gridproxy

import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.threefold.gridproxy.model
// import freeflowuniverse.crystallib.installers.threefold.griddriver

@[heap]
pub struct GridProxyClient {
pub mut:
	http_client httpconnection.HTTPConnection
}

pub enum TFGridNet {
	main
	test
	dev
	qa
}

@[heap]
struct GridproxyFactory {
mut:
	instances map[string]&GridProxyClient
}

fn init_factory() GridproxyFactory {
	mut ef := GridproxyFactory{}
	return ef
}

// Singleton creation
const factory = init_factory()

fn factory_get() &GridproxyFactory {
	return &factory
}

fn gridproxy_url_get(net TFGridNet) string {
	return match net {
		.main { 'https://gridproxy.grid.tf' }
		.test { 'https://gridproxy.test.grid.tf' }
		.dev { 'https://gridproxy.dev.grid.tf' }
		.qa { 'https://gridproxy.qa.grid.tf/' }
	}
}

// return which net in string form
fn tfgrid_net_string(net TFGridNet) string {
	return match net {
		.main { 'main' }
		.test { 'test' }
		.dev { 'dev' }
		.qa { 'qa' }
	}
}

@[params]
pub struct GridProxyClientArgs {
pub mut:
	net   TFGridNet = .main
	cache bool
}

// get returns a gridproxy client for the given net.
//
//```
// net TFGridNet = .main
// cache bool
//```
pub fn new(args GridProxyClientArgs) !&GridProxyClient {
	mut f := factory_get()
	netstr := tfgrid_net_string(args.net)
	if netstr !in factory.instances {
		url := gridproxy_url_get(args.net)
		mut httpconn := httpconnection.new(
			name:  'gridproxy_${netstr}'
			url:   url
			cache: args.cache
		)!
		// do the settings on the connection
		httpconn.cache.expire_after = 7200 // make the cache timeout 2h
		mut connection := GridProxyClient{
			http_client: httpconn
		}
		f.instances[netstr] = &connection
	}
	return f.instances[netstr] or {
		return error_with_code('http client error: unknow error happened while trying to access the GridProxyClient instance',
			err_grid_client)
	}
}

pub fn nodefilter() !model.NodeFilter {
	return model.NodeFilter{}
}

pub fn contractfilter() !model.ContractFilter {
	return model.ContractFilter{}
}

pub fn farmfilter() !model.FarmFilter {
	return model.FarmFilter{}
}

pub fn twinfilter() !model.TwinFilter {
	return model.TwinFilter{}
}

pub fn statfilter() !model.StatFilter {
	return model.StatFilter{}
}
