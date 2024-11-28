module authorization

import log
import db.sqlite

pub struct Authorizer {
	// roles map[string]Role
	// mu t:
	// assets map[string]Asset // assets mapped by their id
	// admins []UserID // list of users which are admins
mut:
	db sqlite.DB
	// 	logger &log.Logger = &log.Logger(&log.Log{
	// 	level: .debug
	// })
}

pub type UserID = string

pub struct Role {
	id      string
	members []UserID
}

pub struct Asset {
	id          string               @[primary]
	permissions int
	acl         []AccessControlEntry @[fkey: 'asset_id']
}

pub struct AccessRequest {
	accessor    UserID // user requesting access to asset
	asset_id    string // id of the asset being accessed
	access_type int    // type of access being requested
}

pub struct AccessControlList {
	entries map[string]AccessControlEntry
}

pub struct AccessControlEntry {
	id          string // identifier of the user or role accessing the asset
	asset_id    string
	permissions int
}

pub enum AccessType {
	read
	write
}

@[params]
pub struct DBBackendConfig {
	db_path string = 'authorization.sqlite'
mut:
	db     sqlite.DB
	logger &log.Logger = &log.Logger(&log.Log{
	level: .info
})
}

pub fn new(config DBBackendConfig) !Authorizer {
	db := sqlite.connect(config.db_path) or { panic(err) }

	sql db {
		create table Asset
	} or { panic(err) }

	return Authorizer{
		// logger: config.logger
		db: db
	}
}

pub fn (mut a Authorizer) add_admin(id string) {
	// a.admins << id
}

pub fn (mut a Authorizer) add_access_control(asset Asset) ! {
	assets := sql a.db {
		select from Asset where id == '${asset.id}'
	} or { panic('err:${err}') }

	if assets.len > 0 {
		return error('Access control for asset ${asset.id} already exists')
	}

	sql a.db {
		insert asset into Asset
	} or { panic('Error insterting asset ${asset} into identity database:${err}') }
}

pub fn (mut a Authorizer) authorize(req AccessRequest) !bool {
	// a.logger.debug('Authorizing access request ${req}')

	assets := sql a.db {
		select from Asset where id == '${req.asset_id}'
	} or { panic('err:${err}') }

	if assets.len == 0 {
		return error('Asset ${req.asset_id} not found')
	}

	asset := assets[0]

	if req.access_type > 3 {
		return true
	}

	aces := asset.acl.filter(it.id == req.accessor)

	// get_entries(
	// 	id: req.accessor
	// 	roles: a.get_roles(req.accessor)
	// )
	return aces.any(req.access_type > it.permissions)
}

// get_roles returns the roles a user has
fn (a Authorizer) get_roles(id UserID) []Role {
	mut roles := []Role{}
	// for _, role in a.roles {
	// 	if id in role.members {
	// 		roles << role
	// 	}
	// }
	return roles
}

pub struct Accessor {
	id    UserID
	roles []Role
}

// get_entries returns the access control entries that belong to an accessor.
fn (acl AccessControlList) get_entries(accessor Accessor) []AccessControlEntry {
	mut aces := []AccessControlEntry{}
	if entry := acl.entries[accessor.id] {
		aces << entry
	}
	for role in accessor.roles {
		if entry := acl.entries[role.id] {
			aces << entry
		}
	}
	return aces
}
