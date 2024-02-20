module docker

import time
import freeflowuniverse.crystallib.osal { exec }
import freeflowuniverse.crystallib.virt.utils

@[heap]
pub struct DockerImage {
pub mut:
	repo    string
	id      string
	tag     string
	digest  string
	size    int // size in MB
	created time.Time
	engine  &DockerEngine @[str: skip]
}

// delete docker image
pub fn (mut image DockerImage) delete(force bool) ! {
	mut forcestr := ''
	if force {
		forcestr = '-f'
	}
	exec(cmd: 'docker rmi ${image.id} ${forcestr}', stdout: false)!
	mut x := 0
	for image2 in image.engine.images {
		if image2.id == image.id {
			image.engine.images.delete(x)
		}
		x += 1
	}
}

// export docker image to tar.gz
pub fn (mut image DockerImage) export(path string) !string {
	exec(cmd: 'docker save ${image.id} > ${path}', stdout: false)!
	return ''
}

// import docker image back into the local env
pub fn (mut image DockerImage) load(path string) ! {
	exec(cmd: 'docker load < ${path}', stdout: false)!
}

pub fn (mut e DockerEngine) images_load() ! {
	e.images = []DockerImage{}
	mut lines := osal.execute_silent("docker images --format '{{.ID}}|{{.Repository}}|{{.Tag}}|{{.Digest}}|{{.Size}}|{{.CreatedAt}}'")!
	for line in lines.split_into_lines() {
		fields := line.split('|').map(utils.clear_str)
		if fields.len < 6 {
			panic('docker image needs to output 6 parts.\n${fields}')
		}
		mut obj := DockerImage{
			engine: &e
		}
		obj.id = fields[0]
		obj.digest = utils.parse_digest(fields[3]) or { '' }
		obj.size = utils.parse_size_mb(fields[4]) or { 0 }
		obj.created = utils.parse_time(fields[5]) or { time.now() }
		e.images << obj
	}
}

@[params]
pub struct ImageGetArgs {
pub:
	repo   string
	tag    string
	digest string
	id     string
}

pub struct ImageGetError {
	Error
pub:
	args     ImageGetArgs
	notfound bool
	toomany  bool
}

pub fn (err ImageGetError) msg() string {
	if err.notfound {
		return 'Could not find image with args:\n${err.args}'
	}
	if err.toomany {
		return 'Found more than 1 image with args:\n${err.args}'
	}
	panic('unknown error for ImageGetError')
}

pub fn (err ImageGetError) code() int {
	if err.notfound {
		return 1
	}
	if err.toomany {
		return 2
	}
	panic('unknown error for ImageGetError')
}

// find image based on repo and optional tag
// args:
// 	repo string
// 	tag string
// 	digest string
// 	id string
pub fn (mut e DockerEngine) image_get(args ImageGetArgs) !&DockerImage {
	mut counter := 0
	mut result_digest := ''
	for i in e.images {
		if args.digest == args.digest {
			return &i
		}
		if args.digest != '' {
			continue
		}
		if args.repo != '' && i.repo != args.repo {
			continue
		}
		if args.tag != '' && i.tag != args.tag {
			continue
		}
		if args.id != '' && i.id != args.id {
			continue
		}
		result_digest = i.digest
		counter += 1
	}
	if counter > 0 {
		return ImageGetError{
			args: args
			toomany: true
		}
	}
	if counter == 0 {
		return ImageGetError{
			args: args
			notfound: true
		}
	}
	return e.image_get(digest: result_digest)!
}

pub fn (mut e DockerEngine) image_exists(args ImageGetArgs) !bool {
	e.image_get(args) or {
		if err.code() == 1 {
			return false
		}
		return err
	}
	return true
}
