module blockchain

import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.core.texttools

pub fn play_asset(p paramsparser.Params) ! {
	mut db := get()!

	ownername := p.get('owner')!

	mut owner := db.owner_get_set(ownername)!

	mut account := Account{
		name:        texttools.name_fix(p.get('name')!)
		secret:      p.get_default('secret', '')!
		pubkey:      p.get('pubkey')!
		description: p.get_default('description', '')!
		cat:         p.get_default('cat', '')!
		owner:       owner.name
		bctype:      parse_blockchain_type(p.get_default('bctype', 'stellar')!)!
	}

	owner.accounts << account
	db.owners << owner
}

fn parse_blockchain_type(bctype string) !BlockChainType {
	match bctype {
		'stellar' { return .stellar }
		'stellar_test' { return .stellar_test }
		else { return error('Invalid blockchain type: ${bctype}') }
	}
}
