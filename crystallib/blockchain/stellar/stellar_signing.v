module stellar

@[params]
pub struct AddSignersArgs {
pub:
	source_account_name ?string
	signers             []TXSigner
}

pub fn (mut client StellarClient) add_signers(args AddSignersArgs) !string {
	mut account_name := client.account_name
	if v := args.source_account_name {
		account_name = v
	}
	account_keys := get_account_keys(account_name)!

	mut tx := client.new_transaction_envelope(account_keys.address)!
	for signer in args.signers {
		if signer.key == tx.tx.source_account {
			tx.add_set_options_op(
				set_options: SetOptions{
					master_weight: signer.weight
				}
			)!
			continue
		}

		tx.add_signer(
			signer: signer
		)!
	}

	mut xdr := tx.xdr()!
	xdr = client.sign_tx(xdr, account_keys.secret)!
	return client.send_tx(xdr)!
}

@[params]
pub struct UpdateThresholdArgs {
pub mut:
	source_account_name ?string
	low_threshold       ?int
	med_threshold       ?int
	high_threshold      ?int
}

pub fn (mut client StellarClient) update_threshold(args UpdateThresholdArgs) !string {
	if args.low_threshold == none && args.med_threshold == none && args.high_threshold == none {
		return error('at least one threshold must be set')
	}

	mut account_name := client.account_name
	if v := args.source_account_name {
		account_name = v
	}
	account_keys := get_account_keys(account_name)!

	mut tx := client.new_transaction_envelope(account_keys.address)!
	tx.add_set_options_op(
		set_options: SetOptions{
			low_threshold: args.low_threshold
			med_threshold: args.med_threshold
			high_threshold: args.high_threshold
		}
	)!

	mut xdr := tx.xdr()!
	xdr = client.sign_tx(xdr, account_keys.secret)!
	return client.send_tx(xdr)!
}

@[params]
pub struct RemoveSignerArgs {
pub:
	source_account_name ?string
	address             string
}

pub fn (mut client StellarClient) remove_signer(args RemoveSignerArgs) !string {
	mut account_name := client.account_name
	if v := args.source_account_name {
		account_name = v
	}
	account_keys := get_account_keys(account_name)!

	mut tx := client.new_transaction_envelope(account_keys.address)!
	tx.add_set_options_op(
		set_options: SetOptions{
			signer: TXSigner{
				key: args.address
				weight: 0
			}
		}
	)!

	mut xdr := tx.xdr()!
	xdr = client.sign_tx(xdr, account_keys.secret)!
	return client.send_tx(xdr)!
}
