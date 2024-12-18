module twinclient

import json

pub fn (mut client TwinClient) algorand_list() ![]BlockChainModel {
	response := client.transport.send('algorand.list', '{}')!
	return json.decode([]BlockChainModel, response.data)
}

pub fn (mut client TwinClient) algorand_exist(name string) !bool {
	data := NameModel{
		name: name
	}
	response := client.transport.send('algorand.exist', json.encode(data).str())!
	return response.data.bool()
}

pub fn (mut client TwinClient) algorand_delete(name string) !bool {
	data := NameModel{
		name: name
	}
	response := client.transport.send('algorand.delete', json.encode(data).str())!
	if response.data.replace('"', '') == 'Deleted' {
		return true
	}
	return false
}

pub fn (mut client TwinClient) algorand_create(name string) !BlockChainCreateModel {
	data := NameModel{
		name: name
	}
	response := client.transport.send('algorand.create', json.encode(data).str())!
	return json.decode(BlockChainCreateModel, response.data)
}

pub fn (mut client TwinClient) algorand_init(name string, secret string) !NameAddressMnemonicModel {
	data := NameSecretModel{
		name:   name
		secret: secret
	}
	response := client.transport.send('algorand.init', json.encode(data).str())!
	mut result := NameAddressMnemonicModel{}
	result.address = response.data
	return result
}

pub fn (mut client TwinClient) algorand_assets(name string) !BlockChainAssetsModel {
	data := NameModel{
		name: name
	}
	response := client.transport.send('algorand.assets', json.encode(data).str())!
	return json.decode(BlockChainAssetsModel, response.data)
}

pub fn (mut client TwinClient) algorand_assets_by_address(address string) !AssetsModel {
	data := AddressModel{
		address: address
	}
	response := client.transport.send('algorand.assetsByAddress', json.encode(data).str())!
	return json.decode(AssetsModel, response.data)
}

pub fn (mut client TwinClient) algorand_get(name string) !BlockChainCreateModel {
	data := NameModel{
		name: name
	}
	response := client.transport.send('algorand.get', json.encode(data).str())!
	return json.decode(BlockChainCreateModel, response.data)
}

pub fn (mut client TwinClient) algorand_sign(name string, content string) !BlockChainSignResponseModel {
	data := BlockchainSignModel{
		name:    name
		content: content
	}
	response := client.transport.send('algorand.sign', json.encode(data).str())!
	return json.decode(BlockChainSignResponseModel, response.data)
}

pub fn (mut client TwinClient) algorand_pay(name string, address_dest string, amount f64, description string) !AlgorandPayResponseModel {
	data := AlgorandPayModel{
		name:         name
		address_dest: address_dest
		amount:       amount
		description:  description
	}
	response := client.transport.send('algorand.pay', json.encode(data).str())!
	return json.decode(AlgorandPayResponseModel, response.data)
}
