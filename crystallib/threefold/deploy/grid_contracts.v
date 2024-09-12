module deploy


import freeflowuniverse.crystallib.threefold.gridproxy
import freeflowuniverse.crystallib.threefold.gridproxy.model as proxy_models

@[params]
pub struct ContractGetArgs{
pub mut:
	active bool = true
	twin_id u64
}

// Retrieves all contracts (active and inactive) on the selected grid network.
//
// This function interacts with the Grid Proxy to retrieve all contracts associated
// with the twin ID of the current deployer (from GridClient).
//
// Returns:
//   - An array of `gridproxy.Contract` containing contract information.
//
// Example:
//   contracts := cn.get_my_contracts()!
pub fn (mut self TFDeployment) tfchain_contracts(args ContractGetArgs) ![]proxy_models.Contract {
	net := resolve_network()!
	args2 := gridproxy.GridProxyClientArgs{
		net: net
		cache: true
	}

	mut proxy := gridproxy.new(args2)!
	if args.active{
		return proxy.get_contracts_active(args.twin_id)
	}else{
		params := proxy_models.ContractFilter{twin_id: args.twin_id}
		return proxy.get_contracts(params)
	}
}

// Resolves the correct grid network based on the `cn.network` value.
//
// This utility function converts the custom network type of GridContracts
// to the appropriate value in `gridproxy.TFGridNet`.
//
// Returns:
//   - A `gridproxy.TFGridNet` value corresponding to the grid network.
fn resolve_network() !gridproxy.TFGridNet {
    mut cfg := get()!
    return match cfg.network {
        .dev { gridproxy.TFGridNet.dev }
        .test { gridproxy.TFGridNet.test }
        .main { gridproxy.TFGridNet.main }
    }
}
