module elements

import freeflowuniverse.crystallib.core.texttools
import os
// import freeflowuniverse.crystallib.ui.console

@[heap]
pub struct Link {
	DocBase
pub mut:
	cat         LinkType
	isexternal  bool // is not linked to a wiki (sites)
	include     bool // means we will not link to the remote location, content will be shown in context of local site
	newtab      bool // means needs to be opened on a new tab
	moresites   bool // this means we can look for the content on multiple source sites, site does not have to be specified
	description string
	url         string
	anchor      string
	// identification of link:
	filename string // is the name of the page/file where the link points too
	path     string // is path in the site
	site     string // is the sitename where the link points too (collection)
	extra    string // e.g. ':size=800x900'
	// internal
	state     LinkState
	error_msg string
}

pub enum LinkType {
	file
	image
	page
	unknown
	html
	data
	email
	anchor
	code
}

pub enum LinkState {
	init // the original state (prob means already processed)
	linkprocessed // means we have found the original information
	ok
	missing
	error
}

pub fn (mut self Link) process() !int {
	if self.processed {
		return 0
	}
	// self.trailing_lf = false
	self.parse()
	for mut child in self.children {
		child.process()!
	}
	self.processed = true
	self.content = ''
	return 1
}

fn (self Link) markdown_include() string {
	// console.print_debug(" ----- LINK MARKDOWN INCLUDE ${self.url} ${self.cat}")
	pd := self.parent_doc_ or { panic('bug there should always be parent_doc') }

	mut link_filename := self.filename

	if self.site != '' {
		link_filename = '${self.site}:${link_filename}'
	} else if pd.collection_name != '' {
		link_filename = '${pd.collection_name}:${link_filename}'
	} else {
		// only add pathname if there is no site (collection) known
		if self.path != '' {
			link_filename = '${self.path}/${link_filename}'
		}
	}

	anchor := if self.anchor != '' { '#${self.anchor}' } else { '' }
	mut out := ''
	if self.cat == LinkType.page || self.cat == LinkType.file || self.cat == LinkType.image
		|| self.cat == LinkType.code {
		mut pre := ''
		if self.cat == LinkType.image {
			pre = '!'
		}

		if self.extra.trim_space() == '' {
			out = '${pre}[${self.description}](${link_filename}${anchor})'
		} else {
			out = '${pre}[${self.description}](${link_filename}${anchor} ${self.extra})'
		}
	} else if self.cat == .anchor {
		out = '[${self.description}](${anchor})'
	} else if self.cat == LinkType.html || self.cat == LinkType.data || self.cat == LinkType.email {
		out = '[${self.description}](${self.url}${anchor})'
	} else {
		panic('bug')
	}
	return out
}

pub fn (self Link) markdown() !string {
	if self.url.contains('header_new') {
		print_backtrace()
	}
	if self.state == .init {
		// means we need to give link before it was processed to resolve the link e.g. in doctree
		return self.markdown_include()
	}

	// represent description as link if there is link child, might be processed
	description := if self.children.len == 1 && self.children[0] is Link {
		self.children[0].markdown()!
	} else {
		self.description
	}

	mut link_filename := self.filename

	anchor := if self.anchor != '' { '#${self.anchor}' } else { '' }
	mut out := ''
	if self.cat == LinkType.page || self.cat == LinkType.file || self.cat == LinkType.image {
		if self.filename.contains(':') {
			return error("should not have ':' in link for image, page or file.\n${self}")
		}
		if self.path != '' {
			link_filename = '${self.path}/${link_filename}'
		}
		mut pre := ''
		if self.cat == LinkType.image {
			pre = '!'
		}

		if self.extra.trim_space() == '' {
			out = '${pre}[${description}](${link_filename}${anchor})'
		} else {
			out = '${pre}[${description}](${link_filename}${anchor} ${self.extra})'
		}
	} else if self.cat == .anchor {
		out = '[${self.description}](${anchor})'
	} else if self.cat == LinkType.html || self.cat == LinkType.email {
		out = '[${description}](${self.url}${anchor})'
	} else {
		panic('bug')
	}

	// if self.cat == LinkType.page {

	// 	// if self.include {
	// 	// 	link_filename = '@${link_filename}'
	// 	// }
	// 	// if self.newtab {
	// 	// 	link_filename = '!${link_filename}'
	// 	// }
	// 	// if self.moresites {
	// 	// 	link_filename = '*${link_filename}'
	// 	// }

	// 	out = '[${self.description}](${link_filename})'
	// }

	return out
}

pub fn (self Link) html() !string {
	return match self.cat {
		.image {'<img src="${self.url}" alt="${self.description}" />'}
	 	else {'<a href="${self.url}">${self.description}</a>'}
	}
}

pub fn (self Link) pug() !string {
	return error('cannot return pug, not implemented')
}

// return path of the filename in the site
pub fn (mut link Link) pathfull() string {
	mut r := '${link.path}/${link.filename}'
	r = r.trim_left('/')
	return r
}

fn (mut link Link) error(msg string) {
	link.state = LinkState.error
	link.error_msg = msg
}

// return the name of the link
pub fn (mut link Link) name_fix_no_underscore_no_ext() string {
	return texttools.name_fix_no_underscore_no_ext(link.filename)
	// return link.filename.all_before_last('.').trim_right('_').to_lower()
}

fn (mut link Link) parse() {
	link.content = link.content.trim_space()
	if link.content.starts_with('!') {
		link.cat = .image
	}
	link.description = link.content.all_after('[').all_before_last(']').trim_space()
	link.url = link.content.all_after('](').all_before(')').trim_space()
	if link.url.contains('#') {
		link.anchor = link.url.all_after('#')
		link.url = link.url.all_before('#')
	} else {
		// TODO: this is temproary fix for non anchor links not working
		// link.url = '${link.url}#'
	}

	// // parse link description as paragraph
	// if link.description != '' {
	// 	link.paragraph_new(mut link.parent_doc(), link.description)
	// 	console.print_debug('debugzoni ${link.children()}')
	// }

	if link.url.contains('://') {
		// linkstate = LinkState.ok
		link.isexternal = true
	}

	// if link.url.starts_with('http')
	// 	|| link.url.starts_with('/')
	// 	|| link.url.starts_with('..') {
	// 	link.cat = LinkType.html
	// 	return
	// }

	if link.url.starts_with('http') {
		link.cat = LinkType.html
		return
	}

	if link.url == '' && link.anchor != '' {
		link.cat = LinkType.anchor
		return
	}

	// AT THIS POINT LINK IS A PAGE OR A FILE
	////////////////////////////////////////

	link.url = link.url.trim_left(' ')

	// deal with special cases where file is not the only thing in ()
	if link.url.trim(' ').contains(' ') {
		// to support something like
		//![](./img/license_threefoldfzc.png ':size=800x900')
		splitted := link.url.trim(' ').split(' ')
		link.filename = splitted[0]
		link.extra = splitted[1]
	} else {
		link.filename = link.url.trim(' ')
	}

	if link.filename.contains('/') {
		link.path = link.filename.all_before_last('/').trim_right('/') // just to make sure it wasn't //
	} else {
		link.path = ''
	}

	// // find the prefix
	// mut prefix_done := false
	// mut filename := []string{}
	// for x in link.filename.trim(' ').split('') {
	// 	if !prefix_done {
	// 		if x == '!' {
	// 			link.newtab = true
	// 			continue
	// 		}
	// 		if x == '@' {
	// 			link.include = true
	// 			continue
	// 		}
	// 		if x == '*' {
	// 			link.moresites = true
	// 			continue
	// 		}
	// 	} else {
	// 		prefix_done = true
	// 	}
	// 	filename << x
	// }
	// link.filename = filename.join('')

	// // trims prefixes from path
	// link.path = link.path.trim_left('!@*')

	// lets now check if there is site info in there
	if link.filename.contains(':') {
		splitted2 := link.filename.split(':')
		if splitted2.len == 2 {
			link.site = texttools.name_fix(splitted2[0])
			// if link.site.starts_with('info_') {
			// 	link.site = link.site[5..]
			// }
			link.filename = splitted2[1]
		} else if splitted2.len > 2 {
			link.error('link can only have 1 x ":"/n${link}')
			return
		} else {
			('should never be here')
		}
	}
	if link.site.contains('/') {
		link.site = link.site.all_after_last('/')
	}

	link.filename = os.base(link.filename).replace('\\', '/')

	if link.path.starts_with('./') {
		link.path = link.path.after('./')
	}

	if link.filename != '' {
		// check which link type
		ext := os.file_ext(link.filename).trim('.').to_lower()

		if ext == '' {
			if link.cat == .image {
				link.error('any link starting with ! needs to be image now ${link.content}')
				return
			}
			link.cat = LinkType.page
			link.filename += '.md'
		} else if ext in ['jpg', 'png', 'svg', 'jpeg', 'gif'] {
			if link.cat != .image {
				link.error('any image needs to start with ! now ${link.content}')
				return
			}
			link.cat = LinkType.image
		} else if ext == 'md' {
			if link.cat == .image {
				link.error('any link starting with ! needs to be image now md, content is ${link.content}')
				return
			}
			link.cat = LinkType.page
			if link.filename.contains('@@') {
				link.filename = '../' + link.filename.all_before('@@') + '/' +
					link.filename.all_after('@@')
				link.site = ''
			}
		} else if ext in ['html', 'htm'] {
			if link.cat == .image {
				link.error('any link starting with ! needs to be image now html, content is ${link.content}')
				return
			}
			link.cat = LinkType.html
			return
		} else if ext in ['v', 'py', 'js', 'c', 'sh'] {
			if link.cat == .image {
				link.error('any link starting with ! needs to be image now code, content is ${link.content}')
				return
			}
			link.cat = LinkType.code
			return
		} else if ext in ['doc', 'docx', 'zip', 'xls', 'pdf', 'xlsx', 'ppt', 'pptx'] {
			if link.cat == .image {
				link.error('any link starting with ! needs to be image now doc, content is ${link.content}')
				return
			}
			link.cat = LinkType.file
			return
		} else if ext in ['json', 'yaml', 'yml', 'toml'] {
			if link.cat == .image {
				link.error('any link starting with ! needs to be image now data, content is ${link.content}')
				return
			}
			link.cat = LinkType.data
			return
		} else if link.url.starts_with('mailto:') {
			if link.cat == .image {
				link.error('any link starting with ! needs to be image now mailto, content is ${link.content}')
				return
			}
			link.cat = LinkType.email
			return
		} else if !link.url.contains_any('./!&;') {
			// link.cat = LinkType.page
			link.error('need to figure out what to do with ${link.url}, its wrong format ')
			return
		} else {
			link.error("${link.url} (no match), ext was:'${ext}'")
			return
		}
		if link.filename.contains(':') {
			panic("should not have ':' in link for page or file (2).\n${link}")
		}
	} else {
		// filename empty
		if !link.url.trim(' ').starts_with('#') {
			link.state = LinkState.error
			link.error('EMPTY LINK.')
			return
		}
	}
}
