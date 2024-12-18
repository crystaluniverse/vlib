module nodepilot

import freeflowuniverse.crystallib.builder

struct NodePilot {
	noderoot   string
	repository string
mut:
	node builder.Node
}

pub fn nodepilot_new(name string, ipaddr string) ?NodePilot {
	node := builder.node_new(name: name, ipaddr: ipaddr)?
	return NodePilot{
		node:       node
		noderoot:   '/root/node-pilot-light'
		repository: 'https://github.com/threefoldtech/node-pilot-light'
	}
}

pub fn (mut n NodePilot) prepare() ? {
	// not how its supposed to be used, todo is the right way
	prepared := n.node.cache.get('nodepilot-prepare') or { '' }
	if prepared != '' {
		return
	}

	if !n.node.cmd_exists('git') {
		n.node.package_install(name: 'git')?
	}

	if !n.node.cmd_exists('docker') {
		n.node.package_install(name: 'ca-certificates curl gnupg lsb-release')?
		n.node.executor.exec('curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg')?

		arch := n.node.executor.exec('dpkg --print-architecture')?.trim_space()
		release := n.node.executor.exec('lsb_release -cs')?.trim_space()

		n.node.executor.exec('echo "deb [arch=${arch} signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu ${release} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null')?

		n.node.package_refresh()?
		n.node.package_install(name: 'docker-ce docker-ce-cli containerd.io')?
		n.node.executor.exec('service docker start')?
	}

	n.node.executor.exec('docker ps -a')?

	if !n.node.executor.dir_exists(n.noderoot) {
		// FIXME: repository is private
		n.node.executor.exec('git clone ${n.repository} ${n.noderoot}')?
	}

	n.node.cache.set('nodepilot-prepare', 'ready', 600)?
}

fn (mut n NodePilot) is_running(s string) bool {
	test := n.node.executor.exec('docker ps | grep ${s}') or { return false }
	return true
}

pub fn (mut n NodePilot) fuse_running() bool {
	return n.is_running('fuse-000')
}

pub fn (mut n NodePilot) fuse() ? {
	rootdir := '/mnt/bc-fuse'
	n.node.executor.exec('root=${rootdir} bash -x ${n.noderoot}/fuse/fuse.sh')?
}

pub fn (mut n NodePilot) harmony_running() bool {
	return n.is_running('harmony')
}

pub fn (mut n NodePilot) harmony() ? {
	rootdir := '/mnt/bc-harmony'
	n.node.executor.exec('root=${rootdir} bash -x ${n.noderoot}/harmony/harmony.sh')?
}

pub fn (mut n NodePilot) pokt_running() bool {
	return n.is_running('pokt-000')
}

pub fn (mut n NodePilot) pokt() ? {
	test := n.node.executor.exec('docker ps | grep pokt-000') or { '' }
	if test != '' {
		return error('Pokt instance already running')
	}

	rootdir := '/mnt/bc-pokt'
	n.node.executor.exec('root=${rootdir} bash -x ${n.noderoot}/pokt/pokt.sh')?
}

fn (mut n NodePilot) overlayfs(ropath string, rwpath string, tmp string, target string) ? {
	n.node.executor.exec('mount -t overlay overlay -o lowerdir=${ropath},upperdir=${rwpath},workdir=${tmp} ${target}')?
}

// make it easy by using the same password everywhere and the same host
// only namespace names needs to be different
fn (mut n NodePilot) zdbfs(host string, meta string, data string, temp string, password string, mountpoint string) ? {
	mut zdbcmd := 'zdbfs ${mountpoint} -o ro '
	zdbcmd += '-o mh=${host} -o mn=${meta} -o ms=${password} '
	zdbcmd += '-o dh=${host} -o dn=${data} -o ds=${password} '
	zdbcmd += '-o th=${host} -o tn=${temp} -o ts=${password}'

	n.node.executor.exec(zdbcmd)?
}

// TODO: pokt chains
