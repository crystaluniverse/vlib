struct VMSpecs {
	deployment_name string
	name            string
	nodeid          string
	pub_sshkeys     []string
	flist           string // if any, if used then ostype not used
	ostype          OSType
}

enum OSType {
	ubuntu_22_04
	ubuntu_24_04
	arch
	alpine
}

struct VMDeployed {
	name   string
	nodeid string
	// size ..
	guid         string
	yggdrasil_ip string
	mycelium_ip  string
}

pub fn (vm VMDeployed) builder_node() builder.Node {
}

// only connect to yggdrasil and mycelium
//
fn vm_deploy(args_ VMSpecs) VMDeployed {
	deploymentstate_db.set(args.deployment_name, 'vm_${args.name}', VMDeployed.json)
}
