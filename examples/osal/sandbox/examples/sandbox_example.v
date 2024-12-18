module main

import freeflowuniverse.crystallib.osal.sandbox
import os

fn do() ! {
	sandbox.install()! // will also do an upgrade of the OS

	mut f := sandbox.new(path_images: '/var/sandbox/images')!

	// get 2 bootstraps to work from
	f.debootstrap(imagename: 'debian', reset: false)! // if reset then will download again
	f.debootstrap(
		imagename:  'ubuntu22'
		repository: 'http://de.archive.ubuntu.com/ubuntu'
		release:    'jammy'
		reset:      false
	)!

	// mut c := f.container_new(startcmd: ["ls", "/", "/proc"])!
	// c.start()!
}

fn main() {
	do() or { panic(err) }
}
