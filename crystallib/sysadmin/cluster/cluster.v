module cluster

pub fn new() Cluster {
	return Cluster{}
}

@[heap]
pub struct Cluster {
pub mut:
	name     string
	secret   string
	active   bool
	nodes    []Node
	admins   []Admin // can remotely access all services on the machine
	services []Service
}

// represents a node in the cluster (a Virtual Machine running Linux)
pub struct Node {
pub mut:
	nr          int
	name        string
	description string
	ipaddress   string
	active      bool
}

pub struct Admin {
pub mut:
	name        string
	description string
	ipaddress   string
	active      bool
}

pub struct Service {
pub mut:
	name        string
	description string
	port        []int
	port_public []int
	active      bool
	installer   string
	depends     []string // on other services, name needs to be unique in cluster
	nodes       []int    // on which nodes does it need to run
	master      int      // if there is a specific master
}

@[params]
pub struct NodeArgs {
pub mut:
	nr          int
	name        string
	description string
	ipaddress   string
	active      bool = true
}

pub fn (mut c Cluster) add_node(nodeargs NodeArgs) !&Node {
	if c.node_exists(nodeargs.nr) {
		return error('Node with number ${nodeargs.nr} already exists')
	}
	node := Node{
		nr:          nodeargs.nr
		name:        nodeargs.name.to_lower()
		description: nodeargs.description
		ipaddress:   nodeargs.ipaddress
		active:      nodeargs.active
	}
	c.nodes << node
	return &node
}

@[params]
pub struct ServiceArgs {
pub mut:
	name        string @[required]
	description string
	port        []int
	port_public []int
	active      bool = true
	installer   string
	depends     []string
	nodes       []int
	master      int
}

// Helper method to add a service to the cluster
pub fn (mut c Cluster) add_service(serviceargs ServiceArgs) !&Service {
	name := serviceargs.name.to_lower()
	if c.service_exists(name) {
		return error('Service with name "${name}" already exists')
	}
	service := Service{
		name:        name
		description: serviceargs.description
		port:        serviceargs.port
		port_public: serviceargs.port_public
		active:      serviceargs.active
		installer:   serviceargs.installer.to_lower()
		depends:     serviceargs.depends.map(it.to_lower())
		nodes:       serviceargs.nodes
		master:      serviceargs.master
	}
	c.services << service
	return &service
}

@[params]
pub struct AdminArgs {
pub mut:
	name        string
	description string
	ipaddress   string
	active      bool
}

// Helper method to add an admin to the cluster
pub fn (mut c Cluster) add_admin(adminargs AdminArgs) {
	admin := Admin{
		name:        adminargs.name.to_lower()
		description: adminargs.description
		ipaddress:   adminargs.ipaddress
		active:      adminargs.active
	}
	c.admins << admin
}

// Check if a node with the given number exists
fn (c Cluster) node_exists(nr int) bool {
	return c.nodes.any(it.nr == nr)
}

// Check if a service with the given name exists
fn (c Cluster) service_exists(name string) bool {
	return c.services.any(it.name == name.to_lower())
}

// Check method to validate the cluster configuration
pub fn (c Cluster) check() ! {
	// Check for unique node numbers
	mut node_numbers := map[int]bool{}
	for node in c.nodes {
		if node.nr in node_numbers {
			return error('Duplicate node number: ${node.nr}')
		}
		node_numbers[node.nr] = true
	}

	// Check for unique service names and lowercase names
	mut service_names := map[string]bool{}
	for service in c.services {
		name := service.name.to_lower()
		if name in service_names {
			return error('Duplicate service name: ${name}')
		}
		service_names[name] = true

		// Check if specified nodes exist
		for node_nr in service.nodes {
			if !c.node_exists(node_nr) {
				return error('Node ${node_nr} specified in service "${name}" does not exist')
			}
		}

		// Check if master node exists
		if service.master != 0 && !c.node_exists(service.master) {
			return error('Master node ${service.master} specified in service "${name}" does not exist')
		}

		// Check if dependent services exist
		for dep in service.depends {
			if !c.service_exists(dep) {
				return error('Dependent service "${dep}" specified in service "${name}" does not exist')
			}
		}
	}
}
