module docker

// import freeflowuniverse.crystallib.develop.gittools
// import freeflowuniverse.crystallib.core.pathlib

pub fn (mut r DockerBuilderRecipe) add_zinit() ! {
	mut pkg_manager := 'apk add'
	if r.platform == .ubuntu {
		pkg_manager = 'apt install'
	}
	r.add_run(
		cmd: '
			${pkg_manager} wget
    	wget https://github.com/threefoldtech/zinit/releases/download/v0.2.5/zinit -O /sbin/zinit
    	chmod +x /sbin/zinit
		touch /etc/environment
		mkdir -p /etc/zinit/
	'
	)!

	r.add_entrypoint(cmd: '/sbin/zinit init --container')!
}

@[params]
pub struct ExecuteArgs {
pub mut:
	source string // is the filename, needs to be embedded
	debug  bool
}

// execute the file as embedded
pub fn (mut r DockerBuilderRecipe) execute(args ExecuteArgs) ! {
	if args.source == '' {
		return error('source cant be empty, \n ${r}')
	}
	path := args.source
	r.add_file_embedded(source: path, dest: '/tmp/${path}', make_executable: true)!
	if !args.debug {
		r.add_run(cmd: '/tmp/${path}')!
	}
}

pub fn (mut r DockerBuilderRecipe) add_nodejsbuilder() ! {
	r.add_package(name: 'nodejs, npm')!
}

pub fn (mut r DockerBuilderRecipe) add_vbuilder() ! {
	r.add_package(name: 'git, musl-dev, clang, gcc, openssh-client, make')!
	r.add_run(
		cmd: "
		git clone --depth 1 https://github.com/vlang/v /opt/vlang 
		cd  /opt/vlang
		make VFLAGS='-cc gcc' 
		./v -version 
		./v symlink
	"
	)!
	r.add_workdir(workdir: '/opt/vlang')!
}

// add ssh server and init scripts (note: zinit needs to be installed)
pub fn (mut r DockerBuilderRecipe) add_sshserver() ! {
	r.add_package(name: 'openssh-server')!

	r.add_zinit_cmd(
		name:    'sshd-setup'
		oneshot: true
		exec:    "
			mkdir -p /run/sshd
			ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
			ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
			ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521
			ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
		"
	)!

	r.add_zinit_cmd(
		name:  'ssh-keys'
		after: 'sshd-setup'
		exec:  '
			if [ ! -d /root/.ssh ]; then
				mkdir -m 700 /root/.ssh
			fi

			echo \$SSH_KEY >> /root/.ssh/authorized_keys
			chmod 600 /root/.ssh/authorized_keys
		'
	)!

	r.add_zinit_cmd(name: 'sshd', exec: '/usr/sbin/sshd -D -e', after: 'sshd-setup')!
}
