module spreadsheet

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.ui.console

pub fn playmacro(action Action) !string {
	console.print_green('playmacro for worksheet')

	sheet_name := action.params.get('sheetname') or {
		return error("can't find sheetname from spreadsheet macro's, define it as sheetname:... .")
	}
	mut sh := sheet_get(sheet_name) or {
		return error("Couldn't find sheetname: ${sheet_name} \nerror:\n${err}")
	}

	// sheet_name := action.params.get('sheetname') or {return error("can't find sheetname from sheet.chart macro.")}
	// mut sh:= sheet_get(sheet_name)!	
	// console.print_debug(sh)

	supported_actions := ['sheet_wiki', 'graph_pie_row', 'graph_line_row', 'graph_bar_row',
		'graph_title_row', 'wiki_row_overview']

	if action.name !in supported_actions {
		return error("Couldn't find macro ${action.name} for spreadsheet:${sheet_name}.")
	}
	// rowname       string   // if specified then its one name
	// namefilter    []string // only include the exact names as secified for the rows
	// includefilter []string // to use with tags filter e.g. ['location:belgium_*'] //would match all words starting with belgium
	// excludefilter []string
	// period_type   PeriodType       // year, month, quarter
	// aggregate     bool = true // if more than 1 row matches should we aggregate or not
	// aggregatetype RowAggregateType = .sum // important if used with include/exclude, because then we group
	// unit          UnitType
	// title         string
	// title_sub     string
	// size          string
	// rowname_show  bool = true // show the name of the row
	// description   string	

	mut p := action.params

	rowname := p.get_default('rowname', '')!
	namefilter := p.get_list_default('namefilter', [])!
	includefilter := p.get_list_default('includefilter', [])!
	excludefilter := p.get_list_default('excludefilter', [])!
	size := p.get_default('size', '')!
	title_sub := p.get_default('title_sub', '')!
	title := p.get_default('title', '')!
	unit := p.get_default('unit', 'normal')!
	unit_e := match unit {
		'thousand' { UnitType.thousand }
		'million' { UnitType.million }
		'billion' { UnitType.billion }
		else { UnitType.normal }
	}
	period_type := p.get_default('period_type', 'year')!
	if period_type !in ['year', 'month', 'quarter'] {
		return error('period type needs to be in year,month,quarter')
	}
	period_type_e := match period_type {
		'year' { PeriodType.year }
		'month' { PeriodType.month }
		'quarter' { PeriodType.quarter }
		else { PeriodType.error }
	}
	if period_type_e == .error {
		return error('period type needs to be in year,month,quarter')
	}

	rowname_show := p.get_default_true('rowname_show')
	descr_show := p.get_default_true('descr_show')

	args := RowGetArgs{
		rowname:       rowname
		namefilter:    namefilter
		includefilter: includefilter
		excludefilter: excludefilter
		period_type:   period_type_e
		unit:          unit_e
		title_sub:     title_sub
		title:         title
		size:          size
		rowname_show:  rowname_show
		descr_show:    descr_show
	}

	mut content := ''

	match action.name {
		// which action is associated with wiki() method
		'sheet_wiki' {
			content = sh.wiki(args) or { panic(err) }
		}
		'graph_title_row' {
			content = sh.wiki_title_chart(args)
		}
		'graph_line_row' {
			content = sh.wiki_line_chart(args)!
		}
		'graph_bar_row' {
			content = sh.wiki_bar_chart(args)!
		}
		'graph_pie_row' {
			content = sh.wiki_pie_chart(args)!
		}
		'wiki_row_overview' {
			content = sh.wiki_row_overview(args)!
		}
		else {
			return error('unexpected action name ${action.name} for sheet macro.')
		}
	}

	content += '\n<BR>\n'
	return content
}
