module blockchain

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.encoder

@[heap]
pub struct Account {
pub mut:
	id          u32
	name        string
	secret      string
	pubkey      string
	description string
	cat         string
	owner       string
	assets      []Asset
	bctype      BlockChainType
}

pub fn (mut self Account) encode() ![]u8 {
	mut e := encoder.new()
	e.add_u32(self.id)
	e.add_string(self.name)
	e.add_string(self.secret)
	e.add_string(self.pubkey)
	e.add_string(self.description)
	e.add_string(self.cat)
	e.add_string(self.owner)

	// Encode assets array length first
	e.add_u16(u16(self.assets.len))
	// Then encode each asset
	for asset in self.assets {
		mut asset_bytes := asset.assettype.encode()!
		e.add_bytes(asset_bytes)
		e.add_int(asset.amount)
	}

	e.add_u8(u8(self.bctype))
	return e.data
}

pub fn (mut self Account) decode(data []u8) !Account {
	mut d := encoder.decoder_new(data)

	// Read basic fields
	id := d.get_u32()
	name := d.get_string()
	secret := d.get_string()
	pubkey := d.get_string()
	description := d.get_string()
	cat := d.get_string()
	owner := d.get_string()

	// Read assets
	assets_len := d.get_u16()
	mut assets := []Asset{cap: assets_len}
	for _ in 0 .. assets_len {
		asset_type_bytes := d.get_bytes()
		mut asset_type := AssetType{}
		asset_type = asset_type.decode(asset_type_bytes)!
		amount := d.get_int()
		assets << Asset{
			amount:    amount
			assettype: asset_type
		}
	}

	bctype := BlockChainType(d.get_u8())

	return Account{
		id:          id
		name:        name
		secret:      secret
		pubkey:      pubkey
		description: description
		cat:         cat
		owner:       owner
		assets:      assets
		bctype:      bctype
	}
}

//////// ACCOUNT GETTERS

@[params]
pub struct AccountGetArgs {
pub mut:
	owner  string @[required]
	name   string @[required]
	bctype BlockChainType
}

pub fn (mut self DADB) accounts_get(args_ AccountGetArgs) ![]&Account {
	mut accounts := []&Account{}
	mut args := args_

	args.name = texttools.name_fix(args.name)
	args.owner = texttools.name_fix(args.owner)

	for mut owner in self.owners {
		if owner.name == args.owner || args.owner == '' {
			for mut account in owner.accounts {
				if account.name == args.name && account.bctype == args.bctype {
					accounts << &account
				}
			}
		}
	}

	return accounts
}

pub fn (mut self DADB) account_get(args_ AccountGetArgs) !&Account {
	mut accounts := self.accounts_get(args_)!
	if accounts.len == 0 {
		return error('No account found with the given name:${args_.name} and blockchain type: ${args_.bctype}')
	} else if accounts.len > 1 {
		return error('Multiple accounts found with the given name:${args_.name} and blockchain type: ${args_.bctype}')
	}

	return accounts[0]
}
