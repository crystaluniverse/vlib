module dao

import freeflowuniverse.crystallib.core.texttools

// is the account on the blockchain
@[heap]
pub struct Account {
pub mut:
	name       string
	address    string   // as used on blockchain, is the public key
	currencies []string // just to have pointer to currencies as used on account, easier to find liquidity pools
}

// make sure account exists in the dao
pub fn (mut dao DAO) account_get(address string, name string) !&Account {
	address_ := texttools.name_fix(address)
	name_ := texttools.name_fix(name)

	if address_ in dao.accounts {
		return dao.accounts[address]
	}

	mut account := Account{
		name:    name_
		address: address_
	}

	dao.accounts[address] = &account

	return dao.accounts[address]
}
