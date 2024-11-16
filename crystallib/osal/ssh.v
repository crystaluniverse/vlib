module osal

import freeflowuniverse.crystallib.core.pathlib
import os

@[params]
pub struct SSHConfig {
pub:
	directory string = os.join_path(os.home_dir(), '.ssh')
}

// Returns a specific SSH key with the given name from the default SSH directory (~/.ssh)
pub fn get_ssh_key(key_name string, config SSHConfig) ?SSHKey {
    mut ssh_dir := pathlib.get_dir(path: config.directory) or {
        return none
    }

    list := ssh_dir.list(files_only: true) or {
        return none
    }
    for file in list.paths {
        if file.name() == key_name {
            return SSHKey{
                name: file.name()
                directory: ssh_dir.path
            }
        }
    }

    return none
}

// Lists SSH keys in the default SSH directory (~/.ssh) and returns an array of SSHKey structs
fn list_ssh_keys(config SSHConfig) ![]SSHKey {
	mut ssh_dir := pathlib.get_dir(path: config.directory) or {
        return error("Error getting ssh directory: ${err}")
    }

    mut keys := []SSHKey{}
    list := ssh_dir.list(files_only: true) or { return error("Failed to list files in SSH directory") }

    for file in list.paths {
        if file.extension() == 'pub' || file.name().starts_with('id_') {
            keys << SSHKey{
                name: file.name()
                directory: ssh_dir.path
			}
        }
    }

    return keys
}

// Creates a new SSH key pair to the specified directory
pub fn new_ssh_key(key_name string, config SSHConfig) !SSHKey {
    ssh_dir := pathlib.get_dir(
        path: config.directory, 
        create: true
    ) or {
        return error("Error getting SSH directory: ${err}")
    }

    // Paths for the private and public keys
    priv_key_path := os.join_path(ssh_dir.path, key_name)
    pub_key_path := '${priv_key_path}.pub'

    // Check if the key already exists
    if os.exists(priv_key_path) || os.exists(pub_key_path) {
        return error("Key pair already exists with the name '${key_name}'")
    }

    panic('implement shhkeygen logic')
    // Generate a random private key (for demonstration purposes)
    // Replace this with actual key generation logic (e.g., calling `ssh-keygen` or similar)
    // private_key_content := '-----BEGIN PRIVATE KEY-----\n${rand.string(64)}\n-----END PRIVATE KEY-----'
    // public_key_content := 'ssh-rsa ${rand.string(64)} user@host'

    // Save the keys to their respective files
    // os.write_file(priv_key_path, private_key_content) or {
    //     return error("Failed to write private key: ${err}")
    // }
    // os.write_file(pub_key_path, public_key_content) or {
    //     return error("Failed to write public key: ${err}")
    // }

    return SSHKey{
        name: key_name
        directory: ssh_dir.path
    }
}