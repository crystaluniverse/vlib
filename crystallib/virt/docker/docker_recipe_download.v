module docker

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal { download }

@[params]
pub struct DownloadArgs {
pub mut:
	name       string // unique name which will be used in the cache
	url        string
	reset      bool // will remove
	minsize_kb u32 = 10 // is always in kb
	maxsize_kb u32
	hash       string // if hash is known, will verify what hash is
	dest       string // if specified will copy to that destination	
	timeout    int = 180
	retry      int = 3
}

// checkout a code repository on right location
pub fn (mut r DockerBuilderRecipe) add_download(args_ DownloadArgs) ! {
	mut args := args_

	if args.dest.len > 0 && args.dest.len < 2 {
		return error("dest is to short (min 3): now '${args.dest}'")
	}

	if args.dest.contains('@name') {
		args.dest = args.dest.replace('@name', args.name)
	}
	if args.url.contains('@name') {
		args.url = args.url.replace('@name', args.name)
	}

	download_dir := '${r.path()}/downloads'

	mut p := download(
		url:        args.url
		name:       args.name
		reset:      args.reset
		dest:       '${download_dir}/${args.name}'
		minsize_kb: args.minsize_kb
		maxsize_kb: args.maxsize_kb
		timeout:    args.timeout
		retry:      args.retry
		hash:       args.hash
	)!

	commonpath := pathlib.path_relative(r.path(), p.path)!
	if commonpath.contains('..') {
		panic('bug should not be')
	}

	r.add_copy(source: commonpath, dest: args.dest)!
}
