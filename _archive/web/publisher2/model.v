module publisher2

import time { Time }
import freeflowuniverse.crystallib.core.pathlib { Path }
import freeflowuniverse.crystallib.core.texttools

pub enum SiteType {
	book // mdbook
	wiki
	web // just html
}

enum State {
	ok
	error
	reset
}

@[heap]
pub struct Publisher {
pub mut:
	// node  &builder.Node
	state  State
	sites  map[string]Site // the key is the prefix as used on webserver
	groups map[string]Group
	users  map[string]User
	acls   map[string]ACL
}

pub fn (mut p Publisher) user_add(name_ string) &User {
	mut name := texttools.name_fix(name_)

	// returns existing user if user with given name exists
	if p.users.keys().contains(name) {
		panic('User already exists')
	}
	mut u := User{
		name: name
	}
	p.users[name] = u
	return &u
}

fn (mut p Publisher) group_add(name_ string) &Group {
	mut name := texttools.name_fix(name_)
	mut u := Group{
		name: name
	}
	p.groups[name] = u
	return &u
}

// pub fn (p Publisher) get_user_sites(user User)

pub fn (mut p Publisher) site_add(name_ string, type_ SiteType) &Site {
	mut name := texttools.name_fix(name_)
	mut u := Site{
		name:      name
		publisher: &p
		sitetype:  type_
	}
	p.sites[name] = u
	return &u
}

pub fn (mut p Publisher) acl_add(name_ string) &ACL {
	mut name := texttools.name_fix(name_)
	mut u := ACL{
		name: name
	}
	p.acls[name] = u
	return &u
}

pub fn (mut p Publisher) site_acl_add(site_ string, acl &ACL) {
	p.sites[site_].authentication.acl << acl
}

pub fn (mut p Publisher) auth_add(email_req bool, email_auth bool) &Authentication {
	mut auth := Authentication{
		email_required:      email_req
		email_authenticated: email_auth
	}
	return &auth
}

@[heap]
pub struct Site {
pub:
	name      string // correspond to key, uses namefix from texttoolsmap[string]Page
	publisher &Publisher @[str: skip] // pointer to sites
	sitetype  SiteType
pub mut:
	path           Path // path where site can be found
	authentication Authentication
	logs           []AccessLog = []
}

pub struct AccessLog {
	user User
	path Path
	time Time
}

// returns the sites that the user has read or write access to
pub fn (p Publisher) get_sites_accessible(username string) map[string]Site {
	mut accesible_sites := map[string]Site{}
	for name, site in p.sites {
		user_access := p.get_access(p.users[username], name)
		if user_access.right == Right.read || user_access.right == Right.write {
			accesible_sites[name] = site
		}
	}
	return accesible_sites
}

pub enum AccessStatus {
	no_access
	email_required
	auth_required
	ok
}

pub struct Access {
pub:
	right  Right
	status AccessStatus
}

//? get highest or lowest right?
// returns the right a user has to a given authentication struct
pub fn (user User) get_access(site Site) Access {
	mut right := Right.block
	auth := site.authentication

	if auth.acl.len > 0 {
		// sets the users right according to the acl.
		for list in auth.acl {
			for entry in list.entries.filter(it.right != .block) {
				for group in entry.groups.filter(it.users.contains(&user)) {
					right = entry.right
				}
				if entry.users.contains(&user) {
					right = entry.right
				}
			}
		}
		if right != Right.read || right != Right.write {
			return Access{
				right:  Right.block
				status: .no_access
			}
		}
	} else {
		// returns read if user meets email requirements and there is no acl
		right = Right.read
	}

	// returns .block if user doesn't meet email authentication requirements
	if auth.email_required {
		if user.emails.len == 0 {
			return Access{
				right:  right
				status: .email_required
			}
		}
		if auth.email_authenticated {
			if !user.emails.any(it.authenticated) {
				return Access{
					right:  right
					status: .auth_required
				}
			}
		}
	}
	return Access{
		right:  right
		status: AccessStatus.ok
	}
}

//? get highest or lowest right?
// returns the right a user has to a given authentication struct
pub fn (p Publisher) get_access(user User, sitename string) Access {
	site := p.sites[sitename]
	mut right := Right.block
	auth := site.authentication

	if auth.acl.len > 0 {
		// sets the users right according to the acl.
		for list in auth.acl {
			for entry in list.entries.filter(it.right != .block) {
				for group in entry.groups.filter(it.users.contains(&user)) {
					right = entry.right
				}
				if entry.users.contains(&user) {
					right = entry.right
				}
			}
		}
		if right != Right.read || right != Right.write {
			return Access{
				right:  Right.block
				status: .no_access
			}
		}
	} else {
		// returns read if user meets email requirements and there is no acl
		right = Right.read
	}

	// returns .block if user doesn't meet email authentication requirements
	if auth.email_required {
		if user.emails.len == 0 {
			return Access{
				right:  right
				status: .email_required
			}
		}
		if auth.email_authenticated {
			if !user.emails.any(it.authenticated) {
				return Access{
					right:  right
					status: .auth_required
				}
			}
		}
	}
	return Access{
		right:  right
		status: .ok
	}
}

// pub fn (mut p Publisher) ace_add(right Right, acl_name string) &ACE {
// 	ace := ACE{right: right}
// 	p.acls[acl_name].entries << ace
// 	return &ace
// }

pub fn (mut p Publisher) ace_add(acl string, right Right) &ACE {
	mut ace := ACE{
		right: right
	}
	p.acls[acl].entries << ace
	return &ace
}

pub fn (mut p Publisher) ace_add_user(mut ace ACE, user &User) &ACE {
	ace.users << user
	return ace
}

pub fn (site Site) auth_add(email_required bool, email_authenticated bool, acl &ACL) &Authentication {
	mut auth := Authentication{
		email_required:      email_required
		email_authenticated: email_authenticated
	}
	auth.acl << acl
	return &auth
}

//? get highest or lowest right?
// returns the right a user has to a given authentication struct
pub fn (p Publisher) get_right(username string, sitename string) Right {
	mut right := Right.block
	auth := p.sites[sitename].authentication
	user := p.users[username]
	if auth.acl.len > 0 {
		// loops acl to find user or user_group entry
		for list in auth.acl {
			for entry in list.entries.filter(it.right != .block) {
				for group in entry.groups.filter(it.users.any(it.name == username)) {
					right = entry.right
				}
				if entry.users.any(it.name == username) {
					right = entry.right
				}
			}
		}
	}
	if auth.email_required {
		if user.emails.len > 0 {
			right = .read
		}
		if auth.email_authenticated {
			if user.emails.any(it.authenticated) {
				right = .read
			}
		}
	}
	return right
}

// if acl not empty then is obliged to use, if email required email need to match USER and the ACE/ACL
// if in combination with email_authenticated, it means we make sure that email is correct, so becomes string
// in future will be compatible with TFConnect
@[heap]
pub struct Authentication {
pub mut:
	email_required      bool   // if true means users need to give their email address (just a form)
	email_authenticated bool   // if true, means user needs to give email address and verify the correctness with email client
	tfconnect           bool   // not used now for future
	kyc                 bool   // not used now for future (KYC/AML)
	acl                 []&ACL // list of people who have access, can be empty if empty there can be passwd
}

// Access Control List
@[heap]
pub struct ACL {
pub mut:
	name    string
	entries []ACE
}

// Access Control Entry
@[heap]
pub struct ACE {
pub mut:
	groups []&Group // pointer to the object as is in the publisher one
	users  []&User  // can be or a user or a group
	right  Right
}

@[heap]
pub struct Group {
pub:
	name string
pub mut:
	users []&User
}

@[heap]
pub struct User {
pub:
	name string
pub mut:
	emails  []Email
	pubkeys []string // optional
	sshkeys []string // optional
}

pub struct Email {
pub mut:
	address       string
	authenticated bool
}

// we just go for these 2 for now
pub enum Right {
	read
	write
	block
}
