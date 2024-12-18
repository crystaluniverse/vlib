module spreadsheet

import freeflowuniverse.crystallib.data.currency
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.ui.console

@[heap]
pub struct Sheet {
pub mut:
	name     string
	rows     map[string]&Row
	nrcol    int = 60
	params   SheetParams
	currency currency.Currency = currency.get('USD')!
}

pub struct SheetParams {
pub mut:
	visualize_cur bool // if we want to show e.g. $44.4 in a cell or just 44.4
}

// find maximum length of a cell (as string representation for a colnr)
// 0 is the first col
// the headers if used are never counted
pub fn (mut s Sheet) cells_width(colnr int) !int {
	mut lmax := 0
	for _, mut row in s.rows {
		if row.cells.len > colnr {
			mut c := row.cell_get(colnr)!
			ll := c.repr().len
			if ll > lmax {
				lmax = ll
			}
		}
	}
	return lmax
}

// walk over all rows, return the max width of the name and/or alias field of a row
pub fn (mut s Sheet) rows_names_width_max() int {
	mut res := 0
	for _, mut row in s.rows {
		if row.name.len > res {
			res = row.name.len
		}
		if row.alias.len > res {
			res = row.alias.len
		}
	}
	return res
}

// walk over all rows, return the max width of the description field of a row
pub fn (mut s Sheet) rows_description_width_max() int {
	mut res := 0
	for _, mut row in s.rows {
		if row.description.len > res {
			res = row.description.len
		}
	}
	return res
}

@[params]
pub struct Group2RowArgs {
pub mut:
	name          string
	include       []string // to use with params filter e.g. ['location:belgium_*'] //would match all words starting with belgium
	exclude       []string
	tags          string
	descr         string
	subgroup      string
	aggregatetype RowAggregateType = .sum
}

// find all rows which have one of the tags
// aggregate (sum) them into one row
// returns a row with the result
// useful to e.g. make new row which makes sum of all salaries for e.g. dev and engineering tag
pub fn (mut s Sheet) group2row(args Group2RowArgs) !&Row {
	name := args.name
	if name == '' {
		return error('name cannot be empty')
	}
	mut rowout := s.row_new(
		name:          name
		tags:          args.tags
		descr:         args.descr
		subgroup:      args.subgroup
		aggregatetype: args.aggregatetype
	)!
	for _, row in s.rows {
		tagstofilter := paramsparser.parse(row.tags)!
		matched := tagstofilter.filter_match(include: args.include, exclude: args.exclude)!
		if matched {
			// console.print_debug("MMMMMAAAAATCH: \n${args.include} ${row.tags}")
			// console.print_debug(row)
			// if true{panic("SDSD")}
			mut x := 0
			for cell in row.cells {
				rowout.cells[x].val += cell.val
				rowout.cells[x].empty = false
				x += 1
			}
		}
	}
	return rowout
}

@[params]
pub struct ToYearQuarterArgs {
pub mut:
	name          string
	namefilter    []string // only include the exact names as specified for the rows
	includefilter []string // matches for the tags
	excludefilter []string // matches for the tags
	period_months int = 12
}

// internal function used by to year and by to quarter
pub fn (s Sheet) tosmaller(args_ ToYearQuarterArgs) !&Sheet {
	mut args := args_
	mut sheetname := args.name
	if sheetname == '' {
		sheetname = s.name + '_year'
	}
	// console.print_debug("to smaller for sheet: ${s.name} rows:${s.rows.len}")
	nrcol_new := int(s.nrcol / args.period_months)
	// println("nr cols: ${s.nrcol} ${args.period_months} ${nrcol_new} ")
	if f64(nrcol_new) != s.nrcol / args.period_months {
		// means we can't do it
		panic('is bug, can only be 4 or 12')
	}
	mut sheet_out := sheet_new(
		name:          sheetname
		nrcol:         nrcol_new
		visualize_cur: s.params.visualize_cur
		curr:          s.currency.name
	)!
	for _, row in s.rows {
		// QUESTION: how to parse period_months
		ok := row.filter(
			rowname:       args.name
			namefilter:    args.namefilter
			includefilter: args.includefilter
			excludefilter: args.excludefilter
			period_type:   .month
		)!
		// console.print_debug("process row in to smaller: ${row.name}, result ${ok}")
		if ok == false {
			continue
		}
		// means filter not specified or filtered
		mut rnew := sheet_out.row_new(
			name:          row.name
			aggregatetype: row.aggregatetype
			tags:          row.tags
			growth:        '0:0.0'
			descr:         row.description
		)!
		for x in 0 .. nrcol_new {
			mut newval := 0.0
			for xsub in 0 .. args.period_months {
				xtot := x * args.period_months + xsub
				// console.print_debug("${row.name} $xtot ${row.cells.len}")
				// if row.cells.len < xtot+1{
				// 	console.print_debug(row)
				// 	panic("too many cells")
				// }
				if row.aggregatetype == .sum || row.aggregatetype == .avg {
					newval += row.cells[xtot].val
				} else if row.aggregatetype == .max {
					if row.cells[xtot].val > newval {
						newval = row.cells[xtot].val
					}
				} else if row.aggregatetype == .min {
					if row.cells[xtot].val < newval {
						newval = row.cells[xtot].val
					}
				} else {
					panic('not implemented')
				}
			}
			if row.aggregatetype == .sum || row.aggregatetype == .max || row.aggregatetype == .min {
				// console.print_debug("sum/max/min ${row.name} $x ${rnew.cells.len}")
				rnew.cells[x].val = newval
			} else {
				// avg
				// console.print_debug("avg ${row.name} $x ${rnew.cells.len}")
				rnew.cells[x].val = newval / args.period_months
			}
		}
	}
	// console.print_debug("to smaller done")
	return sheet_out
}

// make a copy of the sheet and aggregate on year
// params
//   name       string
//   rowsfilter []string
//   tagsfilter []string
// tags if set will see that there is at least one corresponding tag per row
// rawsfilter is list of names of rows which will be included
pub fn (mut s Sheet) toyear(args ToYearQuarterArgs) !&Sheet {
	mut args2 := args
	args2.period_months = 12
	return s.tosmaller(args2)
}

// make a copy of the sheet and aggregate on quarter
// params
//   name       string
//   rowsfilter []string
//   tagsfilter []string
// tags if set will see that there is at least one corresponding tag per row
// rawsfilter is list of names of rows which will be included
pub fn (mut s Sheet) toquarter(args ToYearQuarterArgs) !&Sheet {
	mut args2 := args
	args2.period_months = 3
	return s.tosmaller(args2)
}

// return array with same amount of items as cols in the rows
//
// for year we return Y1, Y2, ...
// for quarter we return Q1, Q2, ...
// for months we returm m1, m2, ...
pub fn (mut s Sheet) header() ![]string {
	// if col + 40 = months	
	if s.nrcol > 40 {
		mut res := []string{}
		for x in 1 .. s.nrcol + 1 {
			res << 'M${x}'
		}
		return res
	}
	// if col + 10 = quarters
	if s.nrcol > 10 {
		mut res := []string{}
		for x in 1 .. s.nrcol + 1 {
			res << 'Q${x}'
		}
		return res
	}

	// else is years
	mut res := []string{}
	for x in 1 .. s.nrcol + 1 {
		res << 'Y${x}'
	}
	return res
}

pub fn (mut s Sheet) json() string {
	// TODO: not done yet
	// return json.encode_pretty(s)
	return ''
}

// find row, report error if not found
pub fn (mut s Sheet) row_get(name string) !&Row {
	mut row := s.rows[name] or { return error('could not find row with name: ${name}') }
	return row
}

pub fn (mut s Sheet) values_get(name string) ![]f64 {
	mut r := s.row_get(name)!
	vs := r.values_get()
	return vs
}

pub fn (mut s Sheet) row_delete(name string) {
	if name in s.rows {
		s.rows.delete(name)
	}
}

// find row, report error if not found
pub fn (mut s Sheet) cell_get(row string, col int) !&Cell {
	mut r := s.row_get(row)!
	mut c := r.cells[col] or {
		return error('could not find cell from col:${col} for row name: ${row}')
	}
	return &c
}

// find row, report error if not found
pub fn (mut s Sheet) delete(name string) {
	if name in s.rows {
		s.rows.delete(name)
	}
}
