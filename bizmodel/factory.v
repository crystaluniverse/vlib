module bizmodel

import freeflowuniverse.crystallib.spreadsheet
import freeflowuniverse.crystallib.texttools
import freeflowuniverse.crystallib.knowledgetree
import freeflowuniverse.crystallib.baobab.actions
// import freeflowuniverse.crystallib.baobab.hero
// import freeflowuniverse.crystallib.baobab.context
// import freeflowuniverse.crystallib.currency

__global (
	bizmodels shared map[string]BizModel
)

pub struct BizModel {
pub mut:
	sheet  spreadsheet.Sheet
	params BizModelArgs
	// currencies currency.Currencies
}

[params]
pub struct BizModelArgs {
pub mut:
	name        string = 'default' // name of bizmodel
	path        string
	git_url     string
	git_reset   bool
	git_root    string
	git_pull    bool
	git_branch  string
	mdbook_name string // if empty will be same as name of bizmodel
	mdbook_path string
	mdbook_dest string // if empty is /tmp/mdbooks/$name
}

pub fn new(args_ BizModelArgs) !knowledgetree.MDBook {
	mut args := args_

	// mut cs := currency.new()

	mut sh := spreadsheet.sheet_new()!

	mut bm := BizModel{
		sheet: sh
		params: args
		// currencies: cs
	}
	bm.load()!

	lock bizmodels {
		bizmodels[args.name] = bm
	}

	if args.name == '' {
		args.name = texttools.name_fix(args.name)
	}

	if args.mdbook_name == '' {
		args.mdbook_name = args.name
	}

	tree_name := 'kapok'
	knowledgetree.new(name: tree_name)!

	mp := macroprocessor_new(args_.name)
	knowledgetree.macroprocessor_add(
		name: tree_name
		processor: mp
	)!

	knowledgetree.scan(
		name: tree_name
		path: args.path
		// heal: true
	)!

	rlock knowledgetrees {
		tree := knowledgetrees['kapok']
		print('start:')
		println(tree.collections.values().map(it.pages.values().map('${it.doc}')))
	}

	// mut tree := args.context.knowledgetree('bizmodel_${args.name}')!

	// mut gs := c.gitstructure('default')!
	// if args.git_root.len > 0 {
	// 	c.gitstructure_new(name: 'bizmodel_${args.name}', root: args.git_root, light: true)
	// }

	// if args.git_url.len > 0 {
	// 	gs = c.gitstructure()!
	// 	mut gr := gs.repo_get_from_url(
	// 		url: args.git_url
	// 		branch: args.git_branch
	// 		pull: args.git_pull
	// 		reset: args.git_reset
	// 	)!
	// 	args.path = gr.path_content_get()
	// }

	// tree.scan(path: args.path)!

	mut book := knowledgetree.book_create(
		path: args.mdbook_path
		name: args.mdbook_name
		tree_name: tree_name
		dest: args.mdbook_dest
	)!

	// mut book := knowledgetree.MDBook{}

	return *book
}

pub fn (mut m BizModel) load() ! {
	println('ACTIONS LOAD ${m.params.name}')
	ap := actions.new(path: m.params.path, defaultcircle: 'bizmodel_${m.params.name}')!
	m.revenue_actions(ap)!
	m.hr_actions(ap)!
	m.funding_actions(ap)!
	m.overhead_actions(ap)!

	// tr.scan(
	// 	path: wikipath
	// 	heal: false
	// )!

	// QUESTION: why was this here?
	// m.sheet.group2row(
	// 	name: 'company_result'
	// 	include: ['pl']
	// 	tags: 'netresult'
	// 	descr: 'Net Company Result.'
	// )!

	// mut company_result := m.sheet.row_get('company_result')!
	// mut cashflow := company_result.recurring(
	// 	name: 'Cashflow'
	// 	tags: 'cashflow'
	// 	descr: 'Cashflow of company.'
	// )!
}
