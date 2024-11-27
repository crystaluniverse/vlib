module stellar

@[params]
pub struct AddSignersArgs {
pub:
	source_address ?string
	signers_to_add []TXSigner
	signers        []string
}

pub fn (mut client StellarClient) add_signers(args AddSignersArgs) !string {
	mut ops := []Operation{}
	mut source_address := client.account_address
	if v := args.source_address {
		source_address = v
	}

	mut tx := client.new_transaction_envelope(client.account_address)!
	for signer in args.signers_to_add {
		ops << Operation{
			source_address: source_address
			threshold:      .high
		}

		if signer.key == tx.tx.source_account {
			tx.add_set_options_op(
				source_account: if v := args.source_address { v } else { none }
				set_options:    SetOptions{
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
	xdr = client.sign_with_signers(xdr, ops, args.signers)!
	tx_info := client.send_tx(xdr)!
	return tx_info.hash
}

@[params]
pub struct UpdateThresholdArgs {
pub mut:
	source_address ?string
	low_threshold  ?int
	med_threshold  ?int
	high_threshold ?int
	signers        []string
}

pub fn (mut client StellarClient) update_threshold(args UpdateThresholdArgs) !string {
	if args.low_threshold == none && args.med_threshold == none && args.high_threshold == none {
		return error('at least one threshold must be set')
	}

	mut source_address := client.account_address
	if v := args.source_address {
		source_address = v
	}

	mut tx := client.new_transaction_envelope(client.account_address)!
	tx.add_set_options_op(
		source_account: if v := args.source_address { v } else { none }
		set_options:    SetOptions{
			low_threshold:  args.low_threshold
			med_threshold:  args.med_threshold
			high_threshold: args.high_threshold
		}
	)!

	mut xdr := tx.xdr()!
	xdr = client.sign_with_signers(xdr, [
		Operation{
			source_address: source_address
			threshold:      .high
		},
	], args.signers)!

	tx_info := client.send_tx(xdr)!
	return tx_info.hash
}

@[params]
pub struct RemoveSignerArgs {
pub:
	source_address ?string
	address        string
	signers        []string
}

pub fn (mut client StellarClient) remove_signer(args RemoveSignerArgs) !string {
	mut source_address := client.account_address
	if v := args.source_address {
		source_address = v
	}

	mut tx := client.new_transaction_envelope(client.account_address)!
	tx.add_set_options_op(
		source_account: if v := args.source_address { v } else { none }
		set_options:    SetOptions{
			signer: TXSigner{
				key:    args.address
				weight: 0
			}
		}
	)!

	mut xdr := tx.xdr()!
	xdr = client.sign_with_signers(xdr, [
		Operation{
			source_address: source_address
			threshold:      .high
		},
	], args.signers)!
	tx_info := client.send_tx(xdr)!
	return tx_info.hash
}
