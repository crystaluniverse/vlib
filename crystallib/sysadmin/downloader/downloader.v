module downloader

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.develop.gittools
import os
import json
import freeflowuniverse.crystallib.ui.console

pub enum DownloadType {
	unknown
	git
	ssh
	pathdir
	pathfile
	httpfile
}

pub struct DownloadMeta {
pub mut:
	args         DownloadArgs
	size_kb      u32
	hash         string
	downloadtype DownloadType
	path         string
}

@[params]
pub struct DownloadArgs {
pub mut:
	name         string // name of the download, if not specified then last part  of url
	downloadpath string // the directory or file where we will download, will be /tmp/downloads/$name
	url          string // url can be ssh:// http(s):// git:// file:// http(s)file:// or just a path
	reset        bool   // to remove all changes
	gitpull      bool   // if you want to force to pull the information
	minsize_kb   u32    // is always in kb
	maxsize_kb   u32
	dest         string // if the dir or file needs to be copied somewhere
	destlink     bool = true // if bool then will link the downloaded content to the dest
	hash         string // if specified then will check the hash of the downloaded content
	metapath     string // if not specified then will not write
	gitstructure ?gittools.GitStructure @[skip; str: skip]
	expand       bool
}

pub fn getlastname(url string) string {
	mut lastname := url.split('/').last()
	if lastname.contains('?') {
		lastname = lastname.split('?')[0]
	}
	if lastname.contains('.') {
		lastname = lastname.split('.')[0]
	}

	return texttools.name_fix(lastname)
}

// downoads url specified dir or file .
// url can be ssh:// http(s):// git://  or just a path
// to a directory linked to a circle '${runner.root}/circles/${circlename}/downloads/${args.name}' .
// will return DownloadMeta, which is als json serialized in above directory .
// if dest specified will link to the dest or copy depending param:destlink
pub fn download(args_ DownloadArgs) !DownloadMeta {
	// console.print_debug(" -- DOWNLOAD ${args_.url}\n$args_")
	mut args := args_

	if args.name == '' {
		args.name = getlastname(args.url)
	}

	if args.name == '' {
		return error('last name should not be empty when downloading.\n${args}')
	}

	if args.dest.contains('@name') {
		args.dest = args.dest.replace('@name', args.name)
	}
	if args.url.contains('@name') {
		args.url = args.url.replace('@name', args.name)
	}

	u := args.url.to_lower().trim_space()

	mut downloadtype := DownloadType.unknown
	mut downloadpath := pathlib.Path{}

	if u.starts_with('http://') || u.starts_with('https://') || u.starts_with('git://') {
		// might be git based checkout
		if args.gitstructure == none {
			mut gs2 := gittools.get()!
			args.gitstructure = gs2
		}
		mut gs := args.gitstructure or { return error('cannot find gitstructure') }
		mut locator := gs.locator_new(args.url)!
		_ = gs.repo_get(locator: locator, pull: args.reset, reset: args.reset)!
		fs_path := locator.path_on_fs()!
		downloadpath = fs_path
		downloadtype = .git
	} else if u.starts_with('ssh://') || u.starts_with('ftp://') {
		return error('Cannot download for runner, unsupported methods:\n${args}')
	} else if u.starts_with('httpsfile') || u.starts_with('httpfile') {
		mut urllocal := args.url.replace('httpsfile', 'https')
		urllocal = urllocal.replace('httpfile', 'http')

		if args.downloadpath == '' {
			filename := u.split('/').last()
			args.downloadpath = '${os.temp_dir()}/downloads/${args.name}/${filename}'
			os.mkdir_all('${os.temp_dir()}/downloads/${args.name}')!
		}

		downloadpath = pathlib.get(args.downloadpath)
		// TODO: need to create dir even if path specified	
		defer {
			downloadpath.delete() or { panic(err) }
		}
		_ := osal.download(
			url:        urllocal
			reset:      args.reset
			dest:       downloadpath.path
			minsize_kb: args.minsize_kb
			maxsize_kb: args.maxsize_kb
		)!
		downloadtype = .httpfile
	} else if args.url.len > 0 {
		downloadpath = pathlib.get(args.url)
		if !(downloadpath.exists()) {
			return error("Cannot download files or dir, because doesn't exist.\n${args}'")
		}
		if downloadpath.is_file() {
			downloadtype = .pathfile
		} else if downloadpath.is_dir() {
			downloadtype = .pathdir
		} else {
			return error("Can only download files or dirs.\n${args}'")
		}
	}

	if !downloadpath.exists() {
		return error("Cannot download, downloaded dir does not exist: '${downloadpath.path}':\n${args}")
	}

	md5hex := downloadpath.md5hex()!
	size_kb := downloadpath.size_kb()!

	if args.minsize_kb > 0 && size_kb < args.minsize_kb {
		return error("Cannot download for runner, min size requirement not met (${size_kb} -> min:${args.minsize_kb}): '${downloadpath.path}':\n${args}")
	}
	if args.maxsize_kb > 0 && size_kb > args.maxsize_kb {
		return error("Cannot download for runner, max size requirement not met (${size_kb} -> min:${args.maxsize_kb}): '${downloadpath.path}':\n${args}")
	}
	mut metaobj := DownloadMeta{
		args:         args
		size_kb:      u32(size_kb)
		hash:         md5hex
		downloadtype: downloadtype
		path:         downloadpath.path
	}
	if args.metapath.len > 0 {
		mut metapatho := pathlib.get(args.metapath)
		metapath := '${metapatho.path_dir()}/${args.name}.meta'
		mut metafile := downloadpath.file_get_new(metapath)!
		metaobj_data := json.encode_pretty(metaobj)
		metafile.write(metaobj_data)!
	}

	if args.expand {
		if true {
			panic('|sdsd')
		}
	}

	if args.dest.len > 0 && args.dest != downloadpath.path {
		// means we need to link or copy the downloaded content to a different location
		// console.print_header(' downloader dest link: ${args.dest}')
		if downloadpath.is_file() {
			// means its a file need to link differently
			if args.destlink {
				// here we link the file *INTO* dir
				// TODO: consider duplicate filenames
				filename := downloadpath.name()
				downloadpath.link('${args.dest}/${filename}', true)!
			} else {
				mut desto := pathlib.get(args.dest)
				downloadpath.copy(dest: desto.path)!
			}
		} else {
			if args.destlink {
				downloadpath.link(args.dest, true) or {
					return error('cannot link ${downloadpath} to ${args.dest}.\n${err}')
				} // delete the dest link
			} else {
				mut desto := pathlib.get(args.dest)
				downloadpath.copy(dest: desto.path)!
			}
		}
	}
	// console.print_debug(metaobj)
	return metaobj
}
