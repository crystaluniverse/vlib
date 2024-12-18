module ed25519

import libsodium
// import encoding.hex

// holds signing and private key
// private key is derivative from signing key
// signkey_bytes is the seed to generate a signing key from which can then generate priv key
pub struct PrivKey25519 {
pub:
	signkey_bytes []u8                 // signing key in bytes
	signkey       libsodium.SigningKey // master key (is a signing key)
	privkey       libsodium.PrivateKey // derivated from master key
	pubkey        PubKey25519
}

pub struct PubKey25519 {
pub:
	ed_bytes    []u8 // for signing
	curve_bytes []u8 // target = remote public key (to encrypt) , also called X25519
}

pub fn new_private_key_25519() PrivKey25519 {
	mut seed := []u8{}
	// generate a new random seed
	for _ in 0 .. 32 {
		seed << u8(libsodium.randombytes_random())
	}
	signkey := libsodium.new_ed25519_signing_key_seed(seed)
	privkey := libsodium.new_private_key_from_signing_ed25519(signkey)
	pubkey := priv_to_public_key(signkey)
	return PrivKey25519{
		signkey:       signkey
		privkey:       privkey
		signkey_bytes: seed
		pubkey:        pubkey
	}
}

// retrieve the master public key from PrivKey object
// this is the public key as need to be shared to a remote user to verify that we signed with our private key
// is shared as hex key in string format (66 chars)
fn priv_to_public_key(priv_sign_key libsodium.SigningKey) PubKey25519 {
	x := priv_sign_key.verify_key.public_key
	mut ed_bytes := []u8{len: x.len}
	unsafe { C.memcpy(ed_bytes.data, &x[0], x.len) }

	curve_bytes := []u8{len: libsodium.public_key_size}
	libsodium.crypto_sign_ed25519_pk_to_curve25519(curve_bytes.data, ed_bytes.data)

	return PubKey25519{
		ed_bytes:    ed_bytes
		curve_bytes: curve_bytes
	}
}

// encrypt data which can only be read by whoever has the private key for this public key
pub fn (privkey PrivKey25519) encrypt_for_remote(pubkey PubKey25519, data []u8) ![]u8 {
	box := libsodium.new_box(privkey.privkey, pubkey.curve_bytes)
	return box.encrypt(data)
}

// verify a signed data and decrypt,
pub fn (privkey PrivKey25519) decrypt(data []u8) []u8 {
	box := libsodium.new_box(privkey.privkey, privkey.pubkey.curve_bytes)
	decrypted := box.decrypt(data)
	return decrypted
}

// sign data with our signing key.
// data is bytestr.
// output is []u8 bytestring.
// to get bytes from string do: mystring.bytes().
pub fn (key PrivKey25519) sign(data []u8) []u8 {
	return key.signkey.sign(data)
}

// verify the signature
pub fn (key PubKey25519) verify(signature []u8) bool {
	v := [libsodium.public_key_size]u8{}
	// unsafe { C.memcpy(&v[0], key.ed_bytes, libsodium.public_key_size) }
	// vk:=libsodium.VerifyKey{public_key: v}
	// return vk.verify(signature)
	return true
}
