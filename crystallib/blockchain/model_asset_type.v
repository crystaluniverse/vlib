module blockchain

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.encoder

pub struct AssetType {
pub mut:
	id     u32
	name   string
	issuer string
	bctype BlockChainType
}

pub enum BlockChainType {
	stellar
	stellar_test
}

fn assettype_encode(val AssetType) ![]u8 {
	mut e := encoder.new()
	e.add_u8(1) // version 1 of encoding
	e.add_u32(val.id)
	e.add_string(val.name)
	e.add_string(val.issuer)
	e.add_u8(u8(val.bctype)) // encode enum as u8 inside unsafe block
	return e.data
}

fn assettype_decode(data []u8) !AssetType {
	mut d := encoder.decoder_new(data)
	version := d.get_u8()
	if version != 1 {
		return error('Unsupported encoding version: ${version}')
	}
	id := d.get_u32()
	name := d.get_string()
	issuer := d.get_string()
	raw_bctype := d.get_u8()

	return AssetType{
		id:     id
		name:   name
		issuer: issuer
		bctype: blockchaintype_get(raw_bctype)!
	}
}

fn blockchaintype_get(nr u8) !BlockChainType {
	// Validate and convert u8 to BlockChainType
	bctype := match nr {
		0 { BlockChainType.stellar }
		1 { BlockChainType.stellar_test }
		else { return error('Invalid BlockChainType value: ${nr}') }
	}
	return bctype
}

// now store in the DB

@[params]
pub struct AssetTypeArgs {
pub mut:
	name   string @[required]
	issuer string @[required]
	bctype BlockChainType
}

pub fn (mut db DADB) assettype_set(args AssetTypeArgs) !AssetType {
	mut at := AssetType{
		name:   texttools.name_fix(args.name)
		issuer: texttools.name_fix(args.issuer)
		bctype: args.bctype
	}
	key := '${at.bctype}_${at.name}'
	if db.db.exists(key: key)! {
		data := db.db.get(key: key)!
	}
	data := assettype_encode(at)!
	at.id = db.set(key: key, value: data)!
	return at
}

pub fn (mut db DADB) assettype_get(id u32) !AssetType {
	data := db.db.get(id: id)!
	mut obj := assettype_decode(data)!
}
