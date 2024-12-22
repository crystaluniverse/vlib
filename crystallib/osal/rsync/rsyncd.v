module rsync

pub struct RsyncD {
pub mut:
	configpath  string = '/etc/rsyncd.conf'
	sites       []RsyncSite
	usermanager UserManager
}

@[params]
pub struct RsyncSite {
pub mut:
	name     string
	path     string
	comment  string
	readonly bool
	list     bool
	auth     string
	secrets  string
}

pub fn rsyncd() !RsyncD {
	mut um := usermanager()!
	mut self := RsyncD{
		usermanager: um
	}
	self.load()!
	return self
}

// add site to the rsyncd config
pub fn (mut self RsyncD) site_add(args_ RsyncSite) ! {
	_ := args_
	// self.sites[args.name]=RsyncSite{name:args.name,}
}

// get all info from existing config file, populate the sites
pub fn (mut self RsyncD) load() ! {
	// TODO: check rsync is installed if not use osal package manager to install
	// TODO: populate sites in the struct
}

pub fn (mut self RsyncD) generate() ! {
	// TODO: generate a new config file (based on previous info on disk as well as new one)
	// TODO: make sure we can add more than 1 user to the user manager

	self.reload()!
}

fn (mut self RsyncD) reload() ! {
	_ := '
	chmod 600 /etc/rsyncd.secrets
	systemctl enable rsync
	systemctl start rsync
	'

	// TODO: execute, maybe we should check its on linux and there is a systemd active, also prob we need to see if we need to start or restart

	// TODO: we should do a test using rsync
}
