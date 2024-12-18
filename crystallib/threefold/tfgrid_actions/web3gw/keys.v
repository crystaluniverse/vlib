module web3gw

import freeflowuniverse.crystallib.core.playbook { Action }

pub fn (mut h Web3GWHandler) keys_define(action Action) ! {
	tfc_mnemonic := action.params.get_default('mnemonic', '')!
	tfc_network := action.params.get_default('network', 'main')!
	if tfc_mnemonic != '' {
		h.clients.tfc_client.load(
			network:  tfc_network
			mnemonic: tfc_mnemonic
		)!
		h.clients.tfg_client.load(
			network:  tfc_network
			mnemonic: tfc_mnemonic
		)!
	}

	btc_host := action.params.get_default('bitcoin_host', '')!
	btc_user := action.params.get_default('bitcoin_user', '')!
	btc_pass := action.params.get_default('bitcoin_pass', '')!
	if btc_host != '' || btc_user != '' || btc_pass != '' {
		h.clients.btc_client.load(
			host: btc_host
			user: btc_user
			pass: btc_pass
		)!
	}

	eth_url := action.params.get_default('ethereum_url', '')!
	eth_secret := action.params.get_default('ethereum_secret', '')!
	if eth_url != '' || eth_secret != '' {
		h.clients.eth_client.load(
			url:    eth_url
			secret: eth_secret
		)!
	}

	str_network := action.params.get_default('stellar_network', 'public')!
	str_secret := action.params.get_default('stellar_secret', '')!
	if str_secret != '' {
		h.clients.str_client.load(
			network: str_network
			secret:  str_secret
		)!
	}
}
