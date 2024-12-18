module secrets

import rand
// import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.ui
// import freeflowuniverse.crystallib.crypt.aes_symmetric
// import crypto.md5
import crypto.sha256
import os
import encoding.base64

@[params]
pub struct SecretArgs {
pub mut:
	key       string @[required]
	default   string // if it doesn't exist yet, will create it with this value
	overwrite string // will overwrite the secret with this value even if it exists
	cat       SecretType
	// reset     bool
}

pub enum SecretType {
	normal
	openssl_hex
	openssl_base64
}

@[params]
pub struct StringArgs {
pub:
	input string
}

pub fn hex_secret(args StringArgs) !string {
	if args.input == '' {
		// If no input string is provided, generate a random hex string
		return rand.hex(24)
	} else {
		// If an input string is provided, use it to generate a consistent hex string
		hash := sha256.sum256(args.input.bytes()).hex()
		return hash[..48] // Return the first 48 characters (24 bytes) of the hash
	}
}

pub fn openssl_hex_secret(args StringArgs) !string {
	if args.input == '' {
		// If no input string is provided, use the original openssl command
		cmd := 'openssl rand -hex 32'
		result := os.execute(cmd)
		if result.exit_code > 0 {
			return error('Command failed with exit code: ${result.exit_code} and error: ${result.output}')
		}
		return result.output.trim_space()
	} else {
		// If an input string is provided, use it to generate a consistent hash
		hash := sha256.sum256(args.input.bytes()).hex()
		return hash[..64] // Return the first 64 characters (32 bytes) of the hash
	}
}

pub fn openssl_base64_secret(args StringArgs) !string {
	if args.input == '' {
		// If no input string is provided, use the original openssl command
		cmd := 'openssl rand -base64 32'
		result := os.execute(cmd)
		if result.exit_code > 0 {
			return error('Command failed with exit code: ${result.exit_code} and error: ${result.output}')
		}
		return result.output.trim_space()
	} else {
		// If an input string is provided, use it to generate a consistent base64 string
		hash := sha256.sum256(args.input.bytes())
		base64_str := base64.encode(hash)
		return base64_str[..44] // Return the first 44 characters (32 bytes in base64)
	}
}
