module tests

import freeflowuniverse.crystallib.twinclient as tw
import os

const random_ip = [
	'201:8090:6444:a4fa:f600:ab10:cf16:b75a',
	'202:8091:6445:a5fa:f700:ab20:cf17:b76a',
	'203:8092:6446:a6fa:f800:ab30:cf18:b77a',
	'204:8093:6447:a7fa:f900:ab40:cf19:b78a',
]

struct Users {
mut:
	all map[string]tw.BlockChainCreateModel
}

const users = Users{}

enum BlockChainFields {
	blockchain_type
	public_key
	mnemonic
	name
}

fn (mut usr Users) set(username string, field BlockChainFields, value string) tw.BlockChainCreateModel {
	match field {
		.blockchain_type { usr.all[username].blockchain_type = value }
		.public_key { usr.all[username].public_key = value }
		.mnemonic { usr.all[username].mnemonic = value }
		.name { usr.all[username].name = value }
	}
	return usr.all[username]
}

fn genrate_dummey_data(username string) tw.BlockChainCreateModel {
	mut u := users
	if username in u.all {
		return users.all[username]
	}
	user := tw.BlockChainCreateModel{
		name: username
	}
	u.all[username] = user
	return user
}

fn init_http_client() !tw.TwinClient {
	mut transport := tw.HttpTwinClient{}
	transport.init('http://localhost:3000')!
	client := tw.grid_client(transport)!
	return client
}

fn init_rmb_client() !tw.TwinClient {
	mut transport := tw.RmbTwinClient{}
	transport.init([143], 5, 5)!
	client := tw.grid_client(transport)!
	return client
}

fn setup_tests(username string) !(tw.TwinClient, tw.BlockChainCreateModel) {
	env_value := os.getenv('TWIN_CLIENT_TYPE').to_lower()
	data := genrate_dummey_data(username)

	match env_value {
		'rmb' {
			client := init_rmb_client()!
			return client, data
		}
		'http' {
			client := init_http_client()!
			return client, data
		}
		else {
			panic('You have to set the `TWIN_CLIENT_TYPE` variable into your environment, choices are: rmb,ws,http.')
		}
	}
}
