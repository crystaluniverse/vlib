module signature

import veb
import db.sqlite
import crypto.hmac
import crypto.sha256
import time

pub struct Signer {
	secret string
pub mut:
    db sqlite.DB
}

@[params]
pub struct SignerConfig {
	db_path string = 'signatures.sqlite'
}

pub fn new(config SignerConfig) &Signer {
    mut signer := Signer {
		db: sqlite.connect('signatures.db') or { panic('Failed to connect to the database') }
	}
	    
	// Create signatures table
    signer.db.exec('CREATE TABLE IF NOT EXISTS signatures (filename TEXT, hash TEXT, user_signature TEXT, server_signature TEXT)') or {
        panic('Failed to create signatures table')
    }

	return &signer
}

// generate a root key for the user
pub fn (s Signer) generate_root_key(user string) string {
    root_key := hmac.new(s.secret.bytes(), user.bytes(), sha256.sum, sha256.block_size).hex()
    return root_key
}

// derive a key from the root key
pub fn (s Signer) derive_key(root_key string, index string) string {
    derived_key := hmac.new(root_key.bytes(), index.bytes(), sha256.sum, sha256.block_size).hex()
	return derived_key
}

// sign a document hash and timestamp
pub fn (s Signer) sign_document(derived_key string, filename string, file_hash string) ! {
    // Server-side timestamp signing
    timestamp := time.now().str()
    server_signature := hmac.new(s.secret.bytes(), "${file_hash}${timestamp}".bytes(), sha256.sum, sha256.block_size).hex()

    // User signs the hash and timestamp
    user_signature := hmac.new(derived_key.bytes(), "${file_hash}${timestamp}".bytes(), sha256.sum, sha256.block_size).hex()

    // Store in SQLite
    s.db.exec('INSERT INTO signatures (filename, hash, user_signature, server_signature) VALUES ("${filename}", "${file_hash}", "${user_signature}", "${server_signature}")') or {
        return error('Failed to store signature')
    }
}

// Endpoint to verify a signature
@['/verify_signature'; post]
pub fn (s Signer) verify_signature(filename string, user_signature string) ! {
    // Retrieve from database
    result := s.db.exec_one('SELECT hash, server_signature FROM signatures WHERE filename = "${filename}"') or {
        return error('Document not found')
    }

    file_hash := result.vals[0]
    server_signature := result.vals[1]

    // Verify server signature
    expected_server_signature := hmac.new("server_secret".bytes(), "${file_hash}${time.now().str()}".bytes(), sha256.sum,
		sha256.block_size).hex()
    if server_signature != expected_server_signature {
        return error('Invalid server signature')
    }

    // Verify user signature
    if user_signature != hmac.new(file_hash.bytes(), server_signature.bytes(), sha256.sum,
		sha256.block_size).hex() {
        return error('Invalid user signature')
    }
}