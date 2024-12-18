module twinclient

import x.json2 as json

pub fn (mut client TwinClient) tfchain_init(name string, secret string) !NameAddressMnemonicModel {
	data := NameSecretModel{
		name:   name
		secret: secret
	}
	response := client.transport.send('tfchain.init', json.encode(data).str())!
	mut result := NameAddressMnemonicModel{}
	result.address = response.data
	return result
}

pub fn (mut client TwinClient) tfchain_get(name string) !BlockChainModel {
	data := NameModel{
		name: name
	}
	response := client.transport.send('tfchain.get', json.encode(data).str())!
	return json.decode[BlockChainModel](response.data)!
}

pub fn (mut client TwinClient) tfchain_update(name string, secret string) !NameSecretModel {
	data := NameSecretModel{
		name:   name
		secret: secret
	}
	client.transport.send('tfchain.update', json.encode(data).str())!
	return data
}

pub fn (mut client TwinClient) tfchain_exist(name string) !bool {
	data := NameModel{
		name: name
	}
	response := client.transport.send('tfchain.exist', json.encode(data).str())!
	return response.data.bool()
}

pub fn (mut client TwinClient) tfchain_list() ![]BlockChainModel {
	response := client.transport.send('tfchain.list', '{}')!
	return json.decode[[]BlockChainModel](response.data)!
}

pub fn (mut client TwinClient) tfchain_balance_by_address(address string) !BalanceResult {
	data := AddressModel{
		address: address
	}
	response := client.transport.send('tfchain.balanceByAddress', json.encode(data).str())!
	return json.decode[BalanceResult](response.data)!
}

pub fn (mut client TwinClient) tfchain_assets(address string) !BlockChainAssetsModel {
	data := AddressModel{
		address: address
	}
	response := client.transport.send('tfchain.assets', json.encode(data).str())!
	return json.decode[BlockChainAssetsModel](response.data)!
}

pub fn (mut client TwinClient) tfchain_create(name string, ip string) !BlockChainCreateResponseModel {
	data := NameIPModel{
		name: name
		ip:   ip
	}
	response := client.transport.send('tfchain.create', json.encode(data).str())!
	return json.decode[BlockChainCreateResponseModel](response.data)!
}

pub fn (mut client TwinClient) tfchain_pay(name string, target_address string, amount f64) ! {
	data := TFChainPayModel{
		name:           name
		target_address: target_address
		amount:         amount
	}
	client.transport.send('tfchain.pay', json.encode(data).str())!
}

pub fn (mut client TwinClient) tfchain_sign(name string, content string) ! {
	data := BlockChainSignModel{
		name:    name
		content: content
	}
	client.transport.send('tfchain.sign', json.encode(data).str())!
	// return TFChainPayModel
}

pub fn (mut client TwinClient) tfchain_delete(name string) !bool {
	data := NameModel{
		name: name
	}
	response := client.transport.send('tfchain.delete', json.encode(data).str())!
	if response.data == 'Deleted' {
		return true
	}
	return false
}
