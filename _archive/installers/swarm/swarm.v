module swarm

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.ui.console

pub struct SwarmArgs {
	reset bool
}

// installs docker & swarm
pub fn install_docker(args SwarmArgs) ! {
	mut installed := true
	out2 := osal.execute_silent('docker version') or {
		installed = false
		console.print_debug('ERROR:' + err.msg())
		'ERROR:' + err.msg()
	}

	if out2.contains('Cannot connect to the Docker daemon') {
		// means docker needs to be started
		return error('cannot find docker')
	}

	if installed {
		return
	}

	if osal.platform() != .ubuntu {
		return error('cannot install docker, wrong platform, for now only ubuntu supported, make sure to unstall docker desktop before trying again.')
	}

	// node.platform_prepare()?
	// ? below prepares platform?

	base_installer.install()!

	// was_done := node.crystaltools_install()?
	// if was_done{
	// 	node.crystaltools_update(reset:args.reset)?
	// }
	// node.upgrade()?

	docker_install := '
		apt-get install ca-certificates curl sudo gnupg lsb-release screen -y

		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
		#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

		#add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

		apt-get update
		apt-get install docker-ce docker-ce-cli containerd.io -y

	'

	// docker_install := '
	// 	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	// 	#THIS IS FOR UBUNTU 20.04 (focal)
	// 	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
	// 	apt update
	// 	apt install docker-ce -y
	// 	systemctl start docker
	// 	systemctl enable docker
	// 	'

	// ? cannot find exec function with args,
	// osal.execute_silent(cmd: docker_install, reset: args.reset, description: 'install docker.')?
	osal.execute_silent(docker_install)!

	// ? Where to get tmux from

	for _ in 1 .. 10 {
		mut out := ''
		out = osal.execute_silent('docker info') or {
			// if err.msg().contains("Cannot connect to the Docker daemon"){
			// 	"noconnection"
			// }
			'ERROR:' + err.msg()
		}
		// console.print_debug(out)
		// if out == "noconnection" {
		// 	panic("SSSSS")
		// }else	
		if !out.starts_with('ERROR:') {
			return
		}
	}
	return error('Could not start docker')
}

// install swarm management solution
pub fn (mut installer Installer) install_portainer() ! {
	install := '
		set -ex
		cd /tmp
		curl -L https://downloads.portainer.io/portainer-agent-stack.yml -o portainer-agent-stack.yml
		docker stack deploy -c portainer-agent-stack.yml portainer
		'
	installer.osal.execute_silent(install)!

	// >TODO: check that the ubuntu is focal
}

pub fn docker_swarm_install(args SwarmArgs) ! {
	i.install_docker(args)!
	ipaddr_master := ipaddr_pub_get()!
	cmd := 'docker swarm init --advertise-addr ${ipaddr_master}'
	osal.execute_silent(cmd)!
}

pub struct SwarmArgsAdd {
pub mut:
	reset  bool
	master Node
}

// specify which node is the master
pub fn (mut installer Installer) docker_swarm_install_add(mut args SwarmArgsAdd) ! {
	args2 := SwarmArgs{args.reset}
	ipaddr := args.master.ipaddr_pub_get()!

	mut token := args.master.exec('docker swarm join-token worker -q')!
	token = token.trim('\n').trim(' \n')

	installer.install_docker(args2)!

	cmd := 'docker swarm leave && docker swarm join --token  ${token} ${ipaddr}:2377'
	console.print_debug(cmd)
	installer.osal.execute_silent(cmd)!
}
