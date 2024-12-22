module spreadsheet

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
// format a sheet properly in wiki format

pub fn (mut s Sheet) wiki(args_ RowGetArgs) !string {
	mut args := args_

	_ := match args.period_type {
		.year { 12 }
		.month { 1 }
		.quarter { 3 }
		else { panic('bug') }
	}

	// console.print_debug("wiki with args:${args}")
	mut sheet := s.filter(args)! // this will do the filtering and if needed make smaller

	mut out := ''
	if args.title.len > 0 {
		out = '## ${args.title}\n\n'
	}
	if args.title != '' {
		out += args.title + '\n\n'
	}

	mut colmax := []int{}
	for x in 0 .. sheet.nrcol {
		colmaxval := sheet.cells_width(x)!
		colmax << colmaxval
	}

	header := sheet.header()!

	// get the width of name and optionally description
	mut names_width := sheet.rows_names_width_max()

	mut header_wiki_items := []string{}
	mut header_wiki_items2 := []string{}
	if args.rowname_show && names_width > 0 {
		header_wiki_items << texttools.expand('|', names_width + 1, ' ')
		header_wiki_items2 << texttools.expand('|', names_width + 1, '-')
	}
	for x in 0 .. sheet.nrcol {
		colmaxval := colmax[x]
		headername := header[x]
		item := texttools.expand(headername, colmaxval, ' ')
		header_wiki_items << '|${item}'
		item2 := texttools.expand('', colmaxval, '-')
		header_wiki_items2 << '|${item2}'
	}
	header_wiki_items << '|'
	header_wiki_items2 << '|'
	header_wiki := header_wiki_items.join('')
	header_wiki2 := header_wiki_items2.join('')

	out += header_wiki + '\n'
	out += header_wiki2 + '\n'

	for _, mut row in sheet.rows {
		mut wiki_items := []string{}
		mut rowname := row.name
		if row.description.len > 0 {
			names_width = sheet.rows_description_width_max()
			rowname = row.description
		}
		if args.rowname_show && names_width > 0 {
			if names_width > 60 {
				names_width = 60
			}
			wiki_items << texttools.expand('|${rowname}', names_width + 1, ' ')
		}
		for x in 0 .. sheet.nrcol {
			colmaxval := colmax[x]
			val := row.cells[x].str()
			item := texttools.expand(val, colmaxval, ' ')
			wiki_items << '|${item}'
		}
		wiki_items << '|'
		wiki2 := wiki_items.join('')
		out += wiki2 + '\n'
	}

	return out
}
