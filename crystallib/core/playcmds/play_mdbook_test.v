module playcmds

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.core.playcmds
import freeflowuniverse.crystallib.core.pathlib

fn test_play_mdbook() {
	mut summary_path := pathlib.get_file(path: '/tmp/mdbook_test/SUMMARY.md', create: true)!
	summar_content := '
- [Page number 1](fruits/apple.md)
- [fruit intro](fruits/intro.md)
- [rpc page](rpc/tfchain.md)
- [vegies](test_vegetables/tomato.md)
'
	summary_path.write(summar_content)!

	mut p := pathlib.get_file(path: '/tmp/heroscript/do.hero', create: true)!
	// 	script := "
	// !!doctree.new
	// 	name: 'tree1'

	// !!doctree.add
	// 	name: 'tree1'
	// 	url:'https://github.com/freeflowuniverse/crystallib/tree/development_doctree4/crystallib/data/doctree/testdata/actions'

	// !!doctree.add
	// 	name: 'tree1'
	// 	url: 'https://github.com/freeflowuniverse/crystallib/tree/development_doctree4/crystallib/data/doctree/testdata/fruits'

	// !!doctree.add
	// 	name: 'tree1'
	// 	url: 'https://github.com/freeflowuniverse/crystallib/tree/development_doctree4/crystallib/data/doctree/testdata/rpc'

	// !!doctree.export
	// 	name: 'tree1'
	// 	path: '/tmp/export_tree1'

	// !!doctree.new
	// 	name: 'tree2'
	// 	fail_on_error: true

	// !!doctree.add
	// 	name: 'tree2'
	// 	url: 'https://github.com/freeflowuniverse/crystallib/tree/development_doctree4/crystallib/data/doctree/testdata/vegetables'

	// !!doctree.export
	// 	name: 'tree2'
	// 	path: '/tmp/export_tree2'

	// !!mdbook.export
	//     title:'ThreeFold Technology'
	//     name:'tech'
	//     summary_path:'${summary_path.path}'
	//     collections:'/tmp/export_tree1,/tmp/export_tree2'
	//     dest: '/tmp/mdbook_export'
	//     production:0 //means we put it in summary
	// "

	s2 := "
!!doctree.new
    name: 'info_tfgrid'
    fail_on_error: false

!!doctree.add 
    name:'info_tfgrid' 
    url:'https://git.ourworld.tf/tfgrid/info_tfgrid/src/branch/main/collections'


!!doctree.export 
    name:'info_tfgrid' 
    path:'~/hero/var/collections/info_tfgrid' 


!!mdbook.export 
    title:'ThreeFold Technology'
    name:'tech'
    summary_url:'https://git.ourworld.tf/tfgrid/info_tfgrid/src/branch/development/books/tech/SUMMARY.md' 
    collections:'~/hero/var/collections/info_tfgrid' 
    production:0 //means we put it in summary
"
	p.write(s2)!

	mut plbook := playbook.new(path: '/tmp/heroscript')!
	playcmds.play_mdbook(mut plbook)!
}
