#!/usr/bin/env -S v -n -w -enable-globals run

import os
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.virt.podman

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

// engine.reset_all()!

// engine.crystal_builder_new()!

engine.hero_build()!

// container_name := 'testarch'

// // install rfs
// osal.exec(
// 	cmd: 'curl -fsSL https://github.com/threefoldtech/rfs/releases/download/v2.0.4/rfs -o /usr/local/bin/rfs'
// )!
// osal.exec(cmd: 'chmod +x /usr/local/bin/rfs')!
// remove the folder if it exists
// osal.exec(cmd: 'rm -fr /tmp/store1')!
// osal.exec(cmd: 'mkdir -p /tmp/mount_fl /tmp/store1')!
// osal.exec(
// 	cmd: 'rfs pack -m output.fl -s dir:///tmp/store1 ${mount_path}'
// )!
// println('mounting to `/tmp/mount_fl` you can check the flist mounted there now, consider doing umount after u finish')
// osal.exec(cmd: 'sudo rfs mount -m output.fl /tmp/mount_fl', timeout: 90000)!
