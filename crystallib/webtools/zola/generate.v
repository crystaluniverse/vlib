module zola

import freeflowuniverse.crystallib.webtools.tailwind
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.webcomponents.preprocessor
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.markdownparser
import freeflowuniverse.crystallib.data.doctree
import os
// import freeflowuniverse.crystallib.core.base

pub fn (mut site ZolaSite) process() ! {
	// site.tree.process_defs()! // process includes
	site.tree.process_includes()! // process includes
	// site.tree.export(
	// 	dest: '${site.path_build.path}',
	// 	reset: true
	// 	keep_structure: true
	// )!

	// export processed content to content dir of build dir

	// os.cp_all('${site.path_build.path}/src/content', '${site.path_build.path}/content', true)!

	mut content_dir := pathlib.get_dir(
		path: '${site.path_build.path}/content'
	)!

	list := content_dir.list(
		recursive: true
		regex: [r'.*\.md$']
	)!

	for file in list.paths {
		_ = markdownparser.new(path: file.path)!
		// mut doc := elements.Doc{...doc}
		// for mut element in doc.children {
		// 	if mut element is elements.Include {
		// 		page := site.tree.page_get(element.content)!
		// 		element.doc = page.doc(mut doctree.DocArgs{})!
		// 	}

		// }
		// if file.path.ends_with('wealth.md') {
		// 	panic(doc)
		// }
	}
}

pub fn (mut site ZolaSite) generate() ! {
	site.process()!

	// set default home page as the first page added
	if !site.pages.any(it.homepage) {
		site.pages[0].homepage = true
	}

	content_dir := pathlib.get_dir(
		path: '${site.path_build.path}/content'
		create: true
	)!

	for mut page in site.pages {
		page.export(content_dir.path)!
	}

	mut header := site.header or { Header{} }

	header.export(content_dir.path)!

	// set default home page as the first page added
	if !site.pages.any(it.homepage) {
		site.pages[0].homepage = true
	}

	static_dir := pathlib.get_dir(
		path: '${site.path_build.path}/static'
		create: true
	)!

	// for mut page in site.pages {
	// 	page.export(content_dir.path)!
	// }

	mut tree := doctree.new(name: 'ws_pages_${site.name}')!
	tree.scan(
		path: '${site.path_build.path}/pages'
		load: true
	)!
	tree.process_includes()!
	tree.export(destination: '${site.path_build.path}/tree')!

	mut img_dir := pathlib.get_dir(
		path: '${site.path_build.path}/tree/src/pages/img'
	)!

	if img_dir.exists() {
		img_dir.move(
			dest: '${static_dir.path}/img'
			delete: true
		)!
	}

	mut errors_file := pathlib.get_file(
		path: '${site.path_build.path}/tree/src/pages/errors.md'
	)!

	errors_file.move(
		dest: '${site.path_build.path}/errors.md'
		delete: true
	)!

	mut src_dir := pathlib.get_dir(
		path: '${site.path_build.path}/tree/src/pages'
	)!

	src_dir.move(
		dest: content_dir.path
		delete: true
	)!

	// src_dir :=

	// if mut people := site.people {
	// 	people.export(content_dir.path)!
	// }
	// if mut news := site.news {
	// 	news.export(content_dir.path)!
	// }

	if mut footer := site.footer {
		footer.export(content_dir.path)!
	}

	for key, mut section in site.sections {
		section_dir := pathlib.get_dir(
			path: '${content_dir.path}/${section.name}'
			create: true
		)!
		section.export(section_dir.path)!
	}

	console.print_header(' website generate: ${site.name} on ${site.path_build.path}')

	mut tw := tailwind.new(
		name: site.name
		path_build: site.path_build.path
		content_paths: [
			'${site.path_build.path}/templates/**/*.html',
			'${site.path_build.path}/content/**/*.md',
			'${site.path_build.path}/content/*.md',
		]
	)!
	preprocessor.preprocess('${site.path_build.path}/content')!

	css_source := '${site.path_build.path}/css/index.css'
	css_dest := '${site.path_build.path}/static/css/index.css'
	tw.compile(css_source, css_dest)!
}

pub fn build(source_path string, build_path string) ! {
	mut cmd := '        #!/usr/bin/env bash		
		set -e
		${osal.profile_path_source()}
		zola -r ${source_path} build -f -o ${build_path}
		'
	cmd = texttools.dedent(cmd)
	mut p_build := pathlib.get_file(path: '${build_path}/build.sh', create: true)!
	p_build.write(cmd)!
	os.chmod(p_build.path, 0o777)!
	osal.exec(cmd: cmd)!
	// mut c := base.context()!
	// mut r := c.redis()!
	// r.set('zola:${site.name}:publish', site.path_publish.path)!
	// r.expire('zola:${site.name}:publish', 3600 * 12)!
}

fn (mut site ZolaSite) template_install() ! {
	config := $tmpl('templates/config.toml')
	mut config_dest := pathlib.get('${site.path_build.path}/config.toml')
	config_dest.write(config)!
}
