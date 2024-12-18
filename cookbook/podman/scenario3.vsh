#!/usr/bin/env -S v -n -w -enable-globals run

import os
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.virt.podman
import freeflowuniverse.crystallib.installers.sysadmintools.rfs
import time

// in this scenario we
// 1- build an image from scratch
// 2- get mount point of this image
// 3- pacstrap arch to that mount point
// 4- install crystallib and vlang
// 5- install hero
// 6- install rfs to back the content of the mount point to store s3 ` in this example we use a local dir just for testing`
// 7- pack the content
// 8- mounting flist to /tmp/mount_fl
//
mut engine := podman.new(reset: false)!
container_name := 'testarch'
mut cont := engine.bcontainer_new(name: container_name, from: 'scratch')!
mount_path := cont.mount_to_path()!
osal.exec(
	cmd: 'pacstrap -c ${mount_path} base bash coreutils vim curl mc unzip systemd vim sudo which openssh fuse2'
)!
// install v and crystallib
cont.run('curl -fsSL https://raw.githubusercontent.com/freeflowuniverse/crystallib/development/scripts/installer.sh -o /tmp/install.sh',
	false)!
cont.run('bash /tmp/install.sh', false)!
// install hero
cont.run('curl -fsSL https://raw.githubusercontent.com/freeflowuniverse/crystallib/development/scripts/install_hero.sh -o install_hero.sh',
	false)!
cont.run('bash -c "redis-server --daemonize yes && bash install_hero.sh"', false)!
cont.set_entrypoint('redis-server')!
cont.commit('localhost/myarch')!
// install rfs

rfs.install()!
// remove the folder if it exists
osal.exec(cmd: 'rm -fr /tmp/store1')!
osal.exec(cmd: 'mkdir -p /tmp/mount_fl /tmp/store1')!
rfs.pack(meta_path: '/tmp/output.fl', stores: ['dir:///tmp/store1'], target: mount_path)!
println('mounting to `/tmp/mount_fl` you can check the flist mounted there now, consider doing umount after u finish')
println('after flist is fully uploaded to test the container do: `podman run -it --rm --read-only  --rootfs /tmp/mount_fl bash`')

// osal.exec(cmd: 'sudo rfs mount -m output.fl /tmp/mount_fl')!

rfs.mount(meta_path: '/tmp/output.fl', target: '/tmp/mount_fl')!
println('flist is mounted..., switching to the container')
time.sleep(time.second * 10)
println('exec bash into container')
osal.exec(
	cmd:   'podman run -it --rm --read-only  --rootfs /tmp/mount_fl bash'
	shell: true
	debug: true
)!
