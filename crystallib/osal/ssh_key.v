module osal

import freeflowuniverse.crystallib.core.pathlib
import os

@[noinit]
pub struct SSHKey {
pub:
    name     string
    directory     string
}

// returns the public ssh key's path of the keypair
pub fn (key SSHKey) public_key_path() !pathlib.Path {
    path_str := os.join_path(key.directory, '${key.name}.pub')
    return pathlib.get_file(path: path_str) or {
        return error('Failed to get public key path: ${err}')
    }
}

// returns the private ssh key's path of the keypair
pub fn (key SSHKey) private_key_path() !pathlib.Path {
    path_str := os.join_path(key.directory, '${key.name}')
    return pathlib.get_file(path: path_str) or {
        return error('Failed to get public key path: ${err}')
    }
}

// returns the public ssh key of the keypair
pub fn (key SSHKey) public_key() !string {
    mut path := key.public_key_path()!
    content := path.read()!
    return content
}

// returns the private ssh key of the keypair
pub fn (key SSHKey) private_key() !string {
    mut path := key.private_key_path()!
    content := path.read()!
    return content
}