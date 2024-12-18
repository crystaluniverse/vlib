module accounts

import freeflowuniverse.crystallib.pathlib
import freeflowuniverse.crystallib.encoder
import encoding.binary as bin
import crypto.ed25519
import libsodium

pub struct PrivKeysSafe {
pub mut:
	path        pathlib.Path
	secret      string
	privatekeys map[int]PrivKey
}

pub struct PrivKey {
pub:
	id      u16
	name    string
	privkey libsodium.PrivateKey
	signkey ed25519.PrivateKey
}

pub fn (pk PrivKey) serialize() []u8 {
	mut e := encoder.encoder_new()
	e.add_u16(pk.id)
	e.add_string(pk.name)
	e.add_bytes(pk.privkey)
	e.add_bytes(pk.signkey)
	return e.data
}

pub fn keysafe_get(path0 string, secret string) !PrivKeysSafe {
	mut safe := PrivKeysSafe{
		path:   pathlib.get(path0)
		secret: secret
	}
	return safe
}

pub fn (mut ks PrivKeysSafe) generate(count int) {
	for i in 0 .. count {
		pubkey, privkey := ed25519.generate_key()!
		pk := PrivKey{
			id:      i
			name:    'name${i}'
			privkey: privkey
			signkey: privkey
		}
		ks.privatekeys[i] = pk
	}
}

pub fn (mut ks PrivKeysSafe) serialize() []u8 {
	mut out := []u8{}
	for key, item in ks.privatekeys {
		out << item.serialize()
	}
	return out
}
