module stellar
import os

pub fn get_address(secret string) !string {
	cmd := 'stellar keys address ${secret} --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to get address: ${result.output}')
	}

	return result.output.trim_space()
}

pub fn get_account_keys(name string) !StellarAccountKeys {
	// Get the public key
	address_result := os.execute('stellar keys address ${name} --quiet')
	if address_result.exit_code != 0 {
		return error('Failed to get public key: ${address_result.output}')
	}
	public_key := address_result.output.trim_space()

	// Get the secret key
	show_result := os.execute('stellar keys show ${name} --quiet')
	if show_result.exit_code != 0 {
		return error('Failed to get secret key: ${show_result.output}')
	}
	secret_key := show_result.output.trim_space()

	// Return the StellarAccountKeys struct
	return StellarAccountKeys{
		name: name
		public_key: public_key
		secret_key: secret_key
	}
}

pub fn get_network_config(network StellarNetwork) !NetworkConfig {
	rpc_url, passphrase := match network {
		.mainnet {
			stellar.mainnet_rpc_url, stellar.mainnet_passphrase
		}
		.testnet {
			stellar.testnet_rpc_url, stellar.testnet_passphrase
		}
	}
	return NetworkConfig{
		url: rpc_url
		passphrase: passphrase
	}
}
