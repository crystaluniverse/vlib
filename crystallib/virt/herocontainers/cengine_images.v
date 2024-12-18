module herocontainers

import freeflowuniverse.crystallib.virt.utils
import freeflowuniverse.crystallib.osal { exec }
import time
import freeflowuniverse.crystallib.ui.console

fn (mut e CEngine) images_load() ! {
	e.images = []Image{}
	mut lines := osal.execute_silent("podman images --format '{{.ID}}||{{.Id}}||{{.Repository}}||{{.Tag}}||{{.Digest}}||{{.Size}}||{{.CreatedAt}}'")!
	for line in lines.split_into_lines() {
		fields := line.split('||').map(utils.clear_str)
		if fields.len != 7 {
			panic('podman image needs to output 7 parts.\n${fields}')
		}
		mut image := Image{
			engine: &e
		}
		image.id = fields[0]
		image.id_full = fields[1]
		image.repo = fields[2]
		image.tag = fields[3]
		image.digest = utils.parse_digest(fields[4]) or { '' }
		image.size = utils.parse_size_mb(fields[5]) or { 0 }
		image.created = utils.parse_time(fields[6]) or { time.now() }
		e.images << image
	}
}

// import herocontainers image back into the local env
pub fn (mut engine CEngine) image_load(path string) ! {
	exec(cmd: 'podman load < ${path}', stdout: false)!
	engine.images_load()!
}

@[params]
pub struct ImageGetArgs {
pub:
	repo    string
	tag     string
	digest  string
	id      string
	id_full string
}

// find image based on repo and optional tag
// args:
// 	repo string
// 	tag string
// 	digest string
// 	id string
// id_full
pub fn (mut e CEngine) image_get(args ImageGetArgs) !Image {
	for i in e.images {
		if args.digest != '' && i.digest == args.digest {
			return i
		}
		if args.id != '' && i.id == args.id {
			return i
		}
		if args.id_full != '' && i.id_full == args.id_full {
			return i
		}
	}

	if args.repo != '' || args.tag != '' {
		mut counter := 0
		mut result_digest := ''
		for i in e.images {
			if args.repo != '' && i.repo != args.repo {
				continue
			}
			if args.tag != '' && i.tag != args.tag {
				continue
			}
			console.print_debug('found image for get: ${i} -- ${args}')
			result_digest = i.digest
			counter += 1
		}
		if counter > 1 {
			return ImageGetError{
				args:    args
				toomany: true
			}
		}
		return e.image_get(digest: result_digest)!
	}
	return ImageGetError{
		args:     args
		notfound: true
	}
}

pub fn (mut e CEngine) image_exists(args ImageGetArgs) !bool {
	e.image_get(args) or {
		if err.code() == 1 {
			return false
		}
		return err
	}
	return true
}

// get buildah containers
pub fn (mut e CEngine) images_get() ![]Image {
	if e.builders.len == 0 {
		e.images_load()!
	}
	return e.images
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

pub struct ImageGetError {
	Error
pub:
	args     ImageGetArgs
	notfound bool
	toomany  bool
}
