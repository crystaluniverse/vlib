module keysafe

import libsodium
import encoding.hex

pub struct VerifyKey {
pub:
	name   string
	remote libsodium.VerifyKey // target public master key
}

// remote is the public master key which needs to verify
pub fn verifykey_new(name string, remote string) !VerifyKey {
	parsed := hex.decode(remote.substr(2, remote.len))!

	v := [libsodium.public_key_size]u8{}
	unsafe { C.memcpy(&v[0], parsed.data, libsodium.public_key_size) }

	return VerifyKey{
		name:   name
		remote: libsodium.VerifyKey{
			public_key: v
		}
	}
}

// verify a signed data, returns true if signature is correct
pub fn (key VerifyKey) verify(data []u8) bool {
	return key.remote.verify(data)
}
