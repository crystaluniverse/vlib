module gittools

import freeflowuniverse.crystallib.core.pathlib


// GitLocation uniquely identifies a Git repository, its online URL, and its location in the filesystem.
@[heap]
pub struct GitLocation {
pub mut:
	provider string // Git provider (e.g., GitHub)
	account  string // Account name
	name     string // Repository name
	branch_or_tag   string // Branch name
	path     string // Path in the repository (not the filesystem)
	anker    string // Position in a file
}


//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////



// Get GitLocation from a path within the Git repository
pub fn (mut gs GitStructure) gitlocation_from_path(path string) !GitLocation {
	mut full_path := pathlib.get(path)
	rel_path := full_path.path_relative(gs.coderoot.path)!

	// Validate the relative path
	mut parts := rel_path.split('/')
	if parts.len < 3 {
		return error("git: path is not valid, should contain provider/account/repository: '${rel_path}'")
	}

	// Extract provider, account, and repository name
	provider := parts[0]
	account := parts[1]
	name := parts[2]
	mut repo_path := if parts.len > 3 { parts[3..].join('/') } else { '' }

	return GitLocation{
		provider: provider
		account:  account
		name:     name
		path:     repo_path
	}
}

// Get GitLocation from a URL
pub fn (mut gs GitStructure) gitlocation_from_url(url string) !GitLocation {
	mut urllower := url.trim_space()
	if urllower == '' {
		return error('url cannot be empty')
	}

	// Normalize URL
	urllower = normalize_url(urllower)

	// Split URL into parts
	mut parts := urllower.split('/')
	mut anchor := ''
	mut path := ''
	mut branch_or_tag := ''

	// Deal with path and anchor
	if parts.len > 4 {
		path = parts[4..].join('/')
		if path.contains('#') {
			parts2 := path.split('#')
			if parts2.len == 2 {
				path = parts2[0]
				anchor = parts2[1]
			} else {
				return error("git: url badly formatted, more than 1 '#' in ${url}")
			}
		}
	}

	// Extract branch if available
	if parts.len > 3 {
		branch_or_tag = parts[3]
		parts[2] = parts[2].replace('.git', '')
	}

	// Validate parts
	if parts.len < 3 {
		return error("git: url badly formatted, not enough parts in '${urllower}' \nparts:\n${parts}")
	}

	// Extract provider, account, and name
	provider := if parts[0] == 'github.com' { 'github' } else { parts[0] }
	account := parts[1]
	name := parts[2].replace('.git', '')

	return GitLocation{
		provider: provider
		account:  account
		name:     name
		branch_or_tag:   branch_or_tag
		path:     path
		anker:    anchor
	}
}

// Return a crystallib path object on the filesystem pointing to the locator
pub fn (mut l GitLocation) patho() !pathlib.Path {
	mut addrpath := pathlib.get_dir(path: '${l.provider}/${l.account}/${l.name}', create: false)!
	if l.path.len > 0 {
		return pathlib.get('${addrpath.path}/${l.path}')
	}
	return addrpath
}

// Normalize the URL for consistent parsing
fn normalize_url(url string) string {
	// Remove common URL prefixes
	if url.starts_with('ssh://') {
		return url[6..].replace(':', '/').replace('//', '/').trim('/')
	}
	if url.starts_with('git@') {
		return url[4..].replace(':', '/').replace('//', '/').trim('/')
	}
	if url.starts_with('http:/') {
		return url[6..].replace(':', '/').replace('//', '/').trim('/')
	}
	if url.starts_with('https:/') {
		return url[7..].replace(':', '/').replace('//', '/').trim('/')
	}
	if url.ends_with('.git') {
		return url[0..url.len - 4].replace(':', '/').replace('//', '/').trim('/')
	}
	return url.replace(':', '/').replace('//', '/').trim('/')
}
