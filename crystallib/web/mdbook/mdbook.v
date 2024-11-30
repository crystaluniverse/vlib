module mdbook

import freeflowuniverse.crystallib.osal
import os
import freeflowuniverse.crystallib.data.doctree.collection
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.develop.gittools

@[heap]
pub struct MDBook {
pub mut:
	name         string
	books        &MDBooks[Config]             @[skip; str: skip]
	path_build   pathlib.Path
	path_publish pathlib.Path
	args         MDBookArgs
	errors       []collection.CollectionError
}

@[params]
pub struct MDBookArgs {
pub mut:
	name  string @[required]
	title string

	foldlevel    int
	printbook    bool
	summary_url  string // url of the summary.md file
	summary_path string // can also give the path to the summary file (can be the dir or the summary itself)
	// doctree_url  string
	// doctree_path string
	publish_path string
	build_path   string
	production   bool
	collections  []string
}

pub fn (mut books MDBooks[Config]) generate(args_ MDBookArgs) !&MDBook {
	console.print_header(' mdbook: ${args_.name}')
	mut cfg := books.config()!
	mut args := args_

	if args.title == '' {
		args.title = args.name
	}
	if args.build_path.len == 0 {
		args.build_path = '${cfg.path_build}/${args.name}'
	}
	if args.publish_path.len == 0 {
		args.publish_path = '${cfg.path_publish}/${args.name}'
	}

	mut mycontext := base.context()!
	mut r := mycontext.redis()!
	r.set('mdbook:${args.name}:build', args.build_path)!
	r.set('mdbook:${args.name}:publish', args.publish_path)!
	r.expire('mdbook:${args.name}:build', 3600 * 12)! // expire after 12h
	r.expire('mdbook:${args.name}:publish', 3600 * 12)!

	mut gs := gittools.get()!

	if args.summary_url.len > 0 {
		repo := gs.get_repo(url:args.summary_url, reset: false, pull: false)!

		// get the path corresponding to the summary_url dir/file
		summary_path := repo.get_path_of_url(args.summary_url)!
		mut summary_dir := pathlib.get_dir(path: summary_path)!

		summary_file_path := summary_dir.file_get_ignorecase('summary.md') or {
			summary_dir = summary_dir.parent()!
			p := summary_dir.file_get_ignorecase('summary.md') or {
				return error('summary from git needs to be dir or file: ${err}')
			}
			p
		}

		args.summary_path = summary_file_path.path
	}

	mut src_path := pathlib.get_dir(path: '${args.build_path}/src', create: true)!
	_ := pathlib.get_dir(path: '${args.build_path}/.edit', create: true)!
	mut collection_set := map[string]bool{}
	for col_path in args.collections {
		// link collections from col_path to src
		mut p := pathlib.get_dir(path: col_path)!
		mut entries := p.list(dirs_only: true, recursive: false)!
		for mut entry in entries.paths {
			if _ := collection_set[entry.name()] {
				return error('collection with name ${entry.name()} already exists')
			}

			collection_set[entry.name()] = true
			entry.link('${src_path.path}/${entry.name()}', true)!
		}
	}

	mut book := MDBook{
		args: args
		path_build: pathlib.get_dir(path: args.build_path, create: true)!
		path_publish: pathlib.get_dir(path: args.publish_path, create: true)!
		books: &books
	}

	mut summary := book.summary(args_.production)!

	mut dir_list := src_path.list(dirs_only: true, include_links: true, recursive: false)!
	for mut collection_dir_path in dir_list.paths {
		collectionname := collection_dir_path.path.all_after_last('/')
		// should always work because done in summary
		// check if there are errors, if yes add to summary
		if os.exists('${collection_dir_path.path}/errors.md') {
			summary.add_error_page(collectionname, 'errors.md')
		}
		// // now link the collection into the build dir
		collection_dirbuild_str := '${book.path_build.path}/src/${collectionname}'.replace('~',
			os.home_dir())
		if !pathlib.path_equal(collection_dirbuild_str, collection_dir_path.path) {
			collection_dir_path.link(collection_dirbuild_str, true)!
		}

		if !os.exists('${collection_dir_path.path}/.linkedpages') {
			continue
		}

		mut linked_pages := pathlib.get_file(path: '${collection_dir_path.path}/.linkedpages')!
		lpagescontent := linked_pages.read()!
		for lpagestr in lpagescontent.split_into_lines().filter(it.trim_space() != '') {
			// console.print_green('find linked page: ${lpagestr}')
			// format $collection:$pagename.md
			splitted := lpagestr.split(':')
			assert splitted.len == 2
			summary.add_page_additional(splitted[0], splitted[1])
		}

		// if collection_dir_path.file_exists('.linkedpages') {
		// 	mut lpages := collection_dir_path.file_get('.linkedpages')!
		// 	lpagescontent := lpages.read()!
		// 	for lpagestr in lpagescontent.split_into_lines().filter(it.trim_space() != '') {
		// 		// console.print_green('find linked page: ${lpagestr}')
		// 		// format $collection:$pagename.md
		// 		splitted := lpagestr.split(':')
		// 		assert splitted.len == 2
		// 		summary.add_page_additional(splitted[0], splitted[1])
		// 	}
		// }
	}

	// create the additional collection (is a system collection)
	addpath := '${book.path_build.path}/src/additional'
	mut a := pathlib.get_file(path: '${addpath}/additional.md', create: true)!
	mut b := pathlib.get_file(path: '${addpath}/errors.md', create: true)!
	mut c := pathlib.get_file(path: '${addpath}/pages.md', create: true)!

	a.write('
# Additional pages

A normal user can ignore these pages, they are for the authors to see e.g. errors

	')!

	b.write('
# Errors

Be the mother for our errors.

	')!
	c.write('
# Additional pages

You can ignore these pages, they are just to get links to work.

	')!

	if book.errors.len > 0 {
		book.errors_report()!

		summary.errors << SummaryItem{
			level: 2
			description: 'errors mdbook'
			pagename: 'errors_mdbook.md'
			collection: 'additional'
		}
	}

	path_summary_str := '${book.path_build.path}/src/SUMMARY.md'
	mut path_summary := pathlib.get_file(path: path_summary_str, create: true)!
	path_summary.write(summary.str())!

	book.template_install()!

	book.generate()!

	console.print_header(' mdbook prepared: ${book.path_build.path}')

	return &book
}

// write errors.md in the collection, this allows us to see what the errors are
fn (book MDBook) errors_report() ! {
	errors_path_str := '${book.path_build.path}/src/additional/errors_mdbook.md'
	mut dest := pathlib.get_file(path: errors_path_str, create: true)!
	if book.errors.len == 0 {
		dest.delete()!
		return
	}
	c := $tmpl('template/errors.md')
	dest.write(c)!
}

@[params]
pub struct ErrorArgs {
pub mut:
	path string
	msg  string
	cat  collection.CollectionErrorCat
}

pub fn (mut book MDBook) error(args ErrorArgs) {
	path2 := pathlib.get(args.path)
	e := collection.CollectionError{
		path: path2
		msg: args.msg
		cat: args.cat
	}
	book.errors << e
	console.print_stderr(args.msg)
}

pub fn (mut book MDBook) open() ! {
	console.print_header('open book: ${book.name}')
	cmd := 'open \'${book.path_publish.path}/index.html\''
	// console.print_debug(cmd)
	// cmd:='bash ${book.path_build.path}/develop.sh'
	osal.exec(cmd: cmd)!
}

pub fn (mut book MDBook) generate() ! {
	console.print_header(' book generate: ${book.name} on ${book.path_build.path}')

	book.summary_image_set()!
	osal.exec(
		cmd: '	
			cd ${book.path_build.path}
			mdbook build --dest-dir ${book.path_publish.path}
			'
		retry: 0
	)!
}

fn (mut book MDBook) template_install() ! {
	// get embedded files to the mdbook dir
	// console.print_debug(book.str())
	mut l := loader()!
	l.load()!
	for item in l.embedded_files {
		dpath := '${book.path_build.path}/${item.path.all_after_first('/')}'
		// console.print_debug(' embed: ${dpath}')
		mut dpatho := pathlib.get_file(path: dpath, create: true)!
		dpatho.write(item.to_string())!
	}

	c := $tmpl('template/book.toml')
	mut tomlfile := book.path_build.file_get_new('book.toml')!
	tomlfile.write(c)!

	c1 := $tmpl('template/build.sh')
	mut file1 := book.path_build.file_get_new('build.sh')!
	file1.write(c1)!
	file1.chmod(0o770)!

	c2 := $tmpl('template/develop.sh')
	mut file2 := book.path_build.file_get_new('develop.sh')!
	file2.write(c2)!
	file2.chmod(0o770)!
}

fn (mut book MDBook) summary_image_set() ! {
	// this is needed to link the first image dir in the summary to the src, otherwise empty home image

	summaryfile := '${book.path_build.path}/src/SUMMARY.md'
	mut p := pathlib.get_file(path: summaryfile)!
	c := p.read()!
	mut first := true
	for line in c.split_into_lines() {
		if !(line.trim_space().starts_with('-')) {
			continue
		}
		if line.contains('](') && first {
			folder_first := line.all_after('](').all_before_last(')')
			folder_first_dir_img := '${book.path_build.path}/src/${folder_first.all_before_last('/')}/img'
			// console.print_debug(folder_first_dir_img)
			// if true{panic("s")}
			if os.exists(folder_first_dir_img) {
				mut image_dir := pathlib.get_dir(path: folder_first_dir_img)!
				image_dir.link('${book.path_build.path}/src/img', true)!
			}

			first = false
		}
	}
}
