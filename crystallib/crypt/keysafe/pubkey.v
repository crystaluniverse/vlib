module keysafe

import libsodium
import encoding.hex

pub struct PubKey {
pub:
	name   string
	source PrivKey // ourself (private key, to sign message)
	remote []u8    // target public key (to encrypt)
}

pub fn pubkey_new(name string, myself PrivKey, remote string) !PubKey {
	parsed := hex.decode(remote.substr(2, remote.len))!

	// convert SigningKey to PrivateKey (ed25519 > x25519)
	// to allow encryption and decryption

	target := []u8{len: libsodium.public_key_size}
	libsodium.crypto_sign_ed25519_pk_to_curve25519(target.data, parsed[0])

	return PubKey{
		name:   name
		source: myself
		remote: target
	}
}

// this will encrypt bytes so that only the owner of this pubkey can decrypt it
pub fn (key PubKey) encrypt(data []u8) ![]u8 {
	box := libsodium.new_box(key.source.privkey, key.remote)
	return box.encrypt(data)
}

// verify a signed data
pub fn (key PubKey) decrypt(data []u8) []u8 {
	box := libsodium.new_box(key.source.privkey, key.remote)
	decrypted := box.decrypt(data)

	return decrypted
}
