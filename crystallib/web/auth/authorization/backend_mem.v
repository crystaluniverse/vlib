module authorization

// import log

// pub struct MemoryBackend {
// 	roles map[string]Role
// mut:
// 	assets map[string]Asset // assets mapped by their id
// 	admins []UserID // list of users which are admins
// 	logger &log.Logger = &log.Logger(&log.Log{
// 	level: .debug
// })
// }

// pub type UserID = string

// pub struct Role {
// 	id      string
// 	members []UserID
// }

// pub struct Asset {
// 	id          string
// 	permissions []AccessType
// 	acl         AccessControlList
// }

// pub struct AccessRequest {
// 	accessor    UserID     // user requesting access to asset
// 	asset_id    string     // id of the asset being accessed
// 	access_type AccessType // type of access being requested
// }

// pub struct AccessControlList {
// 	entries map[string]AccessControlEntry
// }

// pub struct AccessControlEntry {
// 	id          string // identifier of the user or role accessing the asset
// 	permissions []AccessType
// }

// pub enum AccessType {
// 	read
// 	write
// }

// pub fn (mut a Authorizer) add_admin(id string) {
// 	a.admins << id
// }

// pub fn (mut a Authorizer) add_access_control(asset Asset) ! {
// 	if asset.id in a.assets {
// 		return error('Access control for asset ${asset.id} already exists')
// 	}
// 	a.assets[asset.id] = asset
// }

// pub fn (mut a Authorizer) authorize(req AccessRequest) !bool {
// 	a.logger.debug('Authorizing access request ${req}')

// 	asset := a.assets[req.asset_id] or { return error('Asset ${req.asset_id} not found') }
// 	if req.access_type in asset.permissions {
// 		return true
// 	}

// 	aces := asset.acl.get_entries(
// 		id: req.accessor
// 		roles: a.get_roles(req.accessor)
// 	)
// 	return aces.any(req.access_type in it.permissions)
// }

// // get_roles returns the roles a user has
// fn (a Authorizer) get_roles(id UserID) []Role {
// 	mut roles := []Role{}
// 	for _, role in a.roles {
// 		if id in role.members {
// 			roles << role
// 		}
// 	}
// 	return roles
// }

// pub struct Accessor {
// 	id    UserID
// 	roles []Role
// }

// // get_entries returns the access control entries that belong to an accessor.
// fn (acl AccessControlList) get_entries(accessor Accessor) []AccessControlEntry {
// 	mut aces := []AccessControlEntry{}
// 	if entry := acl.entries[accessor.id] {
// 		aces << entry
// 	}
// 	for role in accessor.roles {
// 		if entry := acl.entries[role.id] {
// 			aces << entry
// 		}
// 	}
// 	return aces
// }
