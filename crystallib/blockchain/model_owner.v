module blockchain

import freeflowuniverse.crystallib.core.texttools

@[heap]
pub struct Owner {
pub mut:
	name     string
	accounts []Account
}

// owner_get_set returns owner by name, if not exist creates new one
pub fn (mut self DADB) owner_get(name_ string) !&Owner {
	name := texttools.name_fix(name_)

	for mut owner in self.owners {
		if owner.name == name {
			return &owner
		}
	}

	mut owner := Owner{
		name:     name
		accounts: []Account{}
	}

	self.owners << owner
	return &self.owners[self.owners.len - 1]
}

// owner_get_set returns owner by name, if not exist creates new one
pub fn (mut self DADB) owner_get_set(name_ string) !&Owner {
	name := texttools.name_fix(name_)

	mut found_owner := &Owner{}

	for mut owner in self.owners {
		if owner.name == name {
			return &owner
		}
	}

	if !found {
		mut owner := Owner{
			name:     name
			accounts: []Account{}
		}
		self.owners << owner
		return &self.owners[self.owners.len - 1]
	}

	return found_owner
}
