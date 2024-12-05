module zola

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.data.markdownparser
import freeflowuniverse.crystallib.data.markdownparser.elements
import os
import freeflowuniverse.crystallib.core.texttools

// add blog to website, can be more than 1, will sync but not overwrite to the destination website
// path   string
// url    string
// branch string
// sshkey string
// pull   bool // will pull if this is set
// reset  bool // this means will pull and reset all changes
// reload bool // reload the cache
//```

const testdir = '${os.dir(@FILE)}/testdata'

fn test_blog_add() ! {
	mut z := new()!
	mut site := z.new(
		name: '${@FN}_site'
	)!

	// test adding post without adding doctree, should produce error
	site.post_add(
		name: 'test_post'
		pointer: 'blog:a_better_understanding_of_wealth'
	) or { assert err.msg() == 'Collection blog not found.' }

	// test adding post after adding doctree, should work
	site.doctree_add(
		url: 'https://github.com/threefoldfoundation/threefold_data/tree/development_zola/content'
	)!
	site.post_add(
		name: 'test_post'
		pointer: 'blog:a_better_understanding_of_wealth.md'
	)!
	assert 'test_post' in site.blog.posts
	// panic(site.blog.posts['test_post'])
}
