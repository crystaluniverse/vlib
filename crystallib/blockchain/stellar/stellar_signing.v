module stellar

import os

@[params]
pub struct SignersAddArgs {
pub mut:
	name    string // name to get source account from
	pubkeys []string
}

@[params]
pub struct AddSignerArgs {
pub:
	source_account_name ?string
	address             string
	weight              int
}

pub fn (mut client StellarClient) add_signer(args AddSignerArgs) ! {
	if args.weight == 0 {
		return error('a signer weight of 0 will remove signer. use remove_signer method to remove signer')
	}

	mut account_name := client.default_account

	if v := args.source_account_name {
		account_name = v
	}

	account_keys := client.account_keys_get(account_name)!
	cmd := 'stellar tx new set-options --source-account ${account_keys.secret_key} --signer ${args.address} --signer-weight ${args.weight} --network ${client.network}'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('transaction failed: ${result.output}')
	}
}

@[params]
pub struct RemoveSignerArgs {
pub:
	source_account_name ?string
	address             string
}

pub fn (mut client StellarClient) remove_signer(args RemoveSignerArgs) ! {
	mut account_name := client.default_account

	if v := args.source_account_name {
		account_name = v
	}

	account_keys := client.account_keys_get(account_name)!
	cmd := 'stellar tx new set-options --source-account ${account_keys.secret_key} --signer ${args.address} --signer-weight 0 --network ${client.network}'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('transaction failed: ${result.output}')
	}
}

pub fn (mut client StellarClient) signers_add(args SignersAddArgs) ! {
	jsondata := '
	{
		"source_account": "GDQP2KPQGKIHYJGXNUIYOMHARUARCA7DRQSV5HRTJNBGKZ2G24AN4IQS",
		"operations": [
			{
			"type": "setOptions",
			"signer": {
				"ed25519PublicKey": "GCFDZK7XWETBVW7LYP2NNCFTELIG44QJJN6O7Q7VRP6WUIXTD6NVZ2GS",
				"weight": 1
			}
			},
			{
			"type": "setOptions",
			"signer": {
				"ed25519PublicKey": "GBAQ3GILDSCFDJFGWSHDTXPOJL4FGSKGK3HDJZPZWIR7LU3JMPCRH2W7",
				"weight": 1
			}
			}
		],
		"fee": 200,
		"sequence_number": "123456789",
		"memo": {
			"type": "none"
		},
		"time_bounds": {
			"min_time": 0,
			"max_time": 0
		}
	}
	'
	xdrpath := '/tmp/add-multiple-signers.xdr'
	os.write_file(xdrpath, jsondata)!
	result := os.execute('stellar xdr from-json --input add-multiple-signers.json --output ${xdrpath}  --network ${client.network}')
	if result.exit_code != 0 {
		return error('Failed to convert JSON to XDR: ${result.output}')
	}
	result2 := os.execute('stellar tx sign --input ${xdrpath} --secret SECRET_KEY --output signed-${xdrpath} --network ${client.network}')
	if result2.exit_code != 0 {
		return error('Failed to sign transaction: ${result2.output}')
	}

	result3 := os.execute('stellar tx submit --input signed-${xdrpath} --network ${client.network}')
	if result3.exit_code != 0 {
		return error('Failed to submit transaction: ${result3.output}')
	}

	// TODO: now check the status of the account to see if the signing has been added

	os.rm(xdrpath)!
	os.rm('signed-${xdrpath}')!
}
