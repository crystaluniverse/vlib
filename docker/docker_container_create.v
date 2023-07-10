module docker

import builder

pub fn (mut e DockerEngine) container_create(args DockerContainerCreateArgs) ?&DockerContainer {
	mut ports := ''
	mut mounts := ''
	mut command := args.command
	mut node := builder.node_get(e.node)?

	for port in args.forwarded_ports {
		ports = ports + '-p $port '
	}

	for mount in args.mounted_volumes {
		mounts += '-v $mount '
	}
	mut image := '$args.image_repo'

	if args.image_tag != '' {
		image = image + ':$args.image_tag'
	}

	if image == 'threefold' || image == 'threefold:latest' || image == '' {
		image = 'threefoldtech/grid3_ubuntu_dev'
		command = '/usr/local/bin/boot.sh'
	}

	// if forwarded ports passed in the args not containing mapping tp ssh (22) create one
	if !contains_ssh_port(args.forwarded_ports) {
		// find random free port in the node
		mut port := e.get_free_port()?
		ports += '-p $port:22/tcp'
	}

	mut cmd := 'docker run --hostname $args.hostname --name $args.name $ports $mounts -d  -t $image $command'
	node.executor.exec(cmd)?
	e.load()?
	mut container := e.container_get(args.name)?

	container.engine = e.name
	return container
}
