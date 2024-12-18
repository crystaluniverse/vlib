module twinclient

import json

pub fn (mut client TwinClient) blockchain_select(name string) ! {
	data := NameModel{
		name: name
	}
	client.transport.send('blockchain.select', json.encode(data).str())!
}

pub fn (mut client TwinClient) blockchain_create(name string, blockchain_type string, ip string) !BlockChainCreateModel {
	data := BlockChainCreateModel{
		name:            name
		blockchain_type: blockchain_type
		ip:              ip
	}
	response := client.transport.send('blockchain.create', json.encode(data).str())!
	println(json.decode(BlockChainCreateModel, response.data)!)
	return json.decode(BlockChainCreateModel, response.data)
}

pub fn (mut client TwinClient) blockchain_sign(content string) !BlockChainSignResponseModel {
	data := BlockchainSignNoNameModel{
		content: content
	}
	response := client.transport.send('blockchain.sign', json.encode(data).str())!
	return json.decode(BlockChainSignResponseModel, response.data)
}

pub fn (mut client TwinClient) blockchain_init(name string, blockchain_type string, secret string) !NameAddressMnemonicModel {
	data := BlockchainInitModel{
		name:            name
		blockchain_type: blockchain_type
		secret:          secret
	}
	response := client.transport.send('blockchain.init', json.encode(data).str())!
	return json.decode(NameAddressMnemonicModel, response.data)
}

pub fn (mut client TwinClient) blockchain_get() !BlockChainCreateModel {
	response := client.transport.send('blockchain.get', '{}')!
	return json.decode(BlockChainCreateModel, response.data)
}

pub fn (mut client TwinClient) blockchain_list(blockchain_type string) ![]BlockChainModel {
	data := BlockchainListModel{
		blockchain_type: blockchain_type
	}
	response := client.transport.send('blockchain.list', json.encode(data).str())!
	return json.decode([]BlockChainModel, response.data)
}

pub fn (mut client TwinClient) blockchain_assets() !BlockChainAssetsModel {
	response := client.transport.send('blockchain.assets', '{}')!
	return json.decode(BlockChainAssetsModel, response.data)
}

pub fn (mut client TwinClient) blockchain_pay(options BlockchainPayNoNameModel) ! {
	client.transport.send('blockchain.pay', json.encode(options).str())!
}

pub fn (mut client TwinClient) blockchain_delete() !bool {
	response := client.transport.send('blockchain.delete', '{}')!
	if response.data == 'Deleted' {
		return true
	}
	return false
}
