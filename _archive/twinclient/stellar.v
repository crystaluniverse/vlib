module twinclient

import json

pub fn (mut client TwinClient) stellar_create(name string) !BlockChainCreateModel {
	data := NameModel{
		name: name
	}
	response := client.transport.send('stellar.create', json.encode(data).str())!
	return json.decode(BlockChainCreateModel, response.data)
}

pub fn (mut client TwinClient) stellar_sign(name string, content string) !BlockChainSignResponseModel {
	data := BlockchainSignModel{
		name:    name
		content: content
	}
	response := client.transport.send('stellar.sign', json.encode(data).str())!
	return json.decode(BlockChainSignResponseModel, response.data)
}

pub fn (mut client TwinClient) stellar_init(name string, secret string) !string {
	// Returns pub key.
	data := NameSecretModel{
		name:   name
		secret: secret
	}
	response := client.transport.send('stellar.init', json.encode(data).str())!
	return response.data
}

pub fn (mut client TwinClient) stellar_get(name string) !StellarWallet {
	data := NameModel{
		name: name
	}
	response := client.transport.send('stellar.get', json.encode(data).str())!
	return json.decode(StellarWallet, response.data)
}

pub fn (mut client TwinClient) stellar_update(name string, secret string) !NameSecretModel {
	data := NameSecretModel{
		name:   name
		secret: secret
	}
	client.transport.send('stellar.update', json.encode(data).str())!
	return data
}

pub fn (mut client TwinClient) stellar_list() ![]BlockChainModel {
	response := client.transport.send('stellar.list', '{}')!
	return json.decode([]BlockChainModel, response.data)
}

pub fn (mut client TwinClient) stellar_assets(name string) !BlockChainAssetsModel {
	data := NameModel{
		name: name
	}
	response := client.transport.send('stellar.assets', json.encode(data).str())!
	return json.decode(BlockChainAssetsModel, response.data)
}

pub fn (mut client TwinClient) stellar_balance_by_address(address string) ![]StellarBalance {
	data := AddressModel{
		address: address
	}
	response := client.transport.send('stellar.balance_by_address', json.encode(data).str())!
	return json.decode([]StellarBalance, response.data)
}

pub fn (mut client TwinClient) stellar_pay(name string, address_dest string, amount f64, asset string, description string) !string {
	data := StellarPayModel{
		name:         name
		address_dest: address_dest
		amount:       amount
		asset:        asset
		description:  description
	}
	response := client.transport.send('stellar.pay', json.encode(data).str())!
	return response.data
}

pub fn (mut client TwinClient) stellar_delete(name string) !bool {
	data := NameModel{
		name: name
	}
	response := client.transport.send('stellar.delete', json.encode(data).str())!
	if response.data == 'Deleted' {
		return true
	}
	return false
}

pub fn (mut client TwinClient) stellar_exist(name string) !bool {
	data := NameModel{
		name: name
	}
	response := client.transport.send('stellar.exist', json.encode(data).str())!
	return response.data.bool()
}
