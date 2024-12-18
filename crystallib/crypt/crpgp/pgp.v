module crpgp

import os
import encoding.hex

#flag -lcrpgp
#include <crpgp.h>

// KeyParams
@[params]
pub struct KeyParams {
	name     string @[required]
	email    string @[required]
	key_type CipherSuite
	length   u32 = 3072
	comment  string
}

pub enum CipherSuite {
	cv25519 // ed_dsa primary, ecdh sub
	rsa     // rsa primary (rsa and bitsize can be parameterized)
}

fn (self KeyParams) id() string {
	comment := if self.comment != '' { '(${self.comment}) ' } else { '' }
	return '${self.name} ${comment}<${self.email}>'
}

pub fn generate_key(k KeyParams) !SignedSecretKey {
	mut primarykey_type := C.KeyType{}
	mut subkey_type := C.KeyType{}
	match k.key_type {
		.cv25519 {
			primarykey_type = C.KeyType{KeyType_Tag.ed_dsa, 0}
			subkey_type = C.KeyType{KeyType_Tag.ecdh, 0}
		}
		.rsa {
			primarykey_type = C.KeyType{KeyType_Tag.rsa, k.length}
			subkey_type = C.KeyType{KeyType_Tag.rsa, k.length}
		}
	}
	builder := new_secret_key_param_builder()!
	builder.primary_key_id(k.id())!
	builder.key_type(primarykey_type)!
	subkey_builder := new_subkey_params_builder()
	subkey_builder.key_type(subkey_type)!
	subkey := subkey_builder.build()!
	builder.subkey(subkey)!
	params := builder.build()!
	sk := params.generate_and_free()!
	ssk := sk.sign()!
	return ssk
}

// import functions
// import public key from ASCII armor text format
pub fn import_publickey(data string) !SignedPublicKey {
	return signed_public_key_from_armored(data)
}

// import public key from ASCII armor file format
pub fn import_publickey_from_file(path string) !SignedPublicKey {
	content := os.read_file(path)!
	return import_publickey(content)
}

// import secret key from ASCII armor text format
pub fn import_secretkey(data string) !SignedSecretKey {
	return signed_secret_key_from_armored(data)
}

// import secret key from ASCII armor file format
pub fn import_secretkey_from_file(path string) !SignedSecretKey {
	content := os.read_file(path)!
	return import_secretkey(content)
}

// Public Key Functions
pub fn (spk &SignedPublicKey) verify_signature(sig &Signature, message string) bool {
	spk.verify(message.bytes(), sig) or { return false }
	return true
}

pub fn (spk &SignedPublicKey) encrypt_from_text(message string) ![]byte {
	return spk.encrypt_with_any(message.bytes())
}

// Secret Key Fucntions
pub fn (ssk &SignedSecretKey) sign_message(message string) !Signature {
	return ssk.create_signature(message.bytes())
}

pub fn (ssk &SignedSecretKey) decrypt_to_text(encrypted_message []byte) !string {
	return ssk.decrypt(encrypted_message)!.bytestr()
}

pub fn (ssk &SignedSecretKey) get_signed_public_key() !SignedPublicKey {
	return ssk.public_key()!.sign_and_free(ssk)
}

// Signature Fucntions
fn (sig &Signature) to_bytes() ![]byte {
	return sig.serialize()
}

pub fn (sig &Signature) to_hex() !string {
	return hex.encode(sig.to_bytes()!)
}

pub fn signature_from_hex(sig string) !Signature {
	sig_bytes := hex.decode(sig)!
	return deserialize_signature(sig_bytes)
}
