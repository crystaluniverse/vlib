module spreadsheet

import freeflowuniverse.crystallib.data.paramsparser
// import freeflowuniverse.crystallib.ui.console

@[heap]
pub struct Row {
pub mut:
	name          string
	alias         string
	description   string
	cells         []Cell
	sheet         &Sheet @[skip; str: skip]
	aggregatetype RowAggregateType
	reprtype      ReprType // how to represent it
	tags          string
	subgroup      string
}

// pub enum RowType{
// 	cur
// 	integer
// 	float
// }

pub enum RowAggregateType {
	unknown
	sum
	avg
	max
	min
}

@[params]
pub struct RowNewParams {
pub mut:
	name          string
	growth        string
	aggregatetype RowAggregateType
	tags          string
	descr         string
	subgroup      string
	extrapolate   bool = true
}

// get a row with a certain name
// you can use the smart extrapolate function to populate the row
// params:
// 	name string
// 	growth string (this is input for the extrapolate function)
//  aggregatetype e.g. sum,avg,max,min  is used to go from months to e.g. year or quarter
//  tags []string e.g. ["hr","hrdev"] attach a tag to a row, can be used later to group
// smart exptrapolation is 3:2,10:5 means end month 3 we start with 2, it grows to 5 on end month 10
pub fn (mut s Sheet) row_new(args_ RowNewParams) !&Row {
	mut args := args_
	if args.aggregatetype == .unknown {
		args.aggregatetype = .sum
	}
	name := args.name.to_lower()
	if name.trim_space() == '' {
		return error('name cannot be empty')
	}
	mut r := Row{
		sheet:         &s
		name:          name
		aggregatetype: args.aggregatetype
		tags:          args.tags
		description:   args.descr
		subgroup:      args.subgroup
	}
	s.rows[name] = &r
	for _ in 0 .. s.nrcol {
		r.cells << Cell{
			row: &r
		}
	}
	assert r.cells.len == s.nrcol
	if args.growth.len > 0 {
		if args.extrapolate {
			if !args.growth.contains(',') && !args.growth.contains(':') {
				args.growth = '0:${args.growth}'
			}
			r.extrapolate(args.growth)!
		} else {
			r.smartfill(args.growth)!
		}
	}
	return &r
}

pub fn (mut r Row) cell_get(colnr int) !&Cell {
	if colnr > r.cells.len {
		return error("Cannot find cell, the cell is out of bounds, the colnr:'${colnr}' is larger than nr of cells:'${r.cells.len}'")
	}
	return &r.cells[colnr]
}

pub fn (mut r Row) values_get() []f64 {
	mut out := []f64{}
	for cell in r.cells {
		out << cell.val
	}
	return out
}

// starting from cell look forward for nrcolls
// make the average
pub fn (r Row) look_forward_avg(colnr_ int, nrcols_ int) !f64 {
	mut colnr := colnr_
	mut nrcols := nrcols_
	if colnr > r.cells.len {
		return error("Cannot find cell, the cell is out of bounds, the colnr:'${colnr}' is larger than nr of cells:'${r.cells.len}'")
	}
	if colnr + nrcols > r.cells.len {
		colnr = r.cells.len - nrcols_
	}
	mut v := 0.0
	for i in colnr .. colnr + nrcols {
		v += r.cells[i].val
	}
	avg := v / f64(nrcols)
	return avg
}

pub fn (r Row) min() f64 {
	mut v := 9999999999999.0
	for cell in r.cells {
		// console.print_debug(cell.val)
		if cell.val < v {
			v = cell.val
		}
	}
	return v
}

pub fn (r Row) max() f64 {
	mut v := 0.0
	for cell in r.cells {
		// console.print_debug(cell.val)
		if cell.val > v {
			v = cell.val
		}
	}
	return v
}

// apply the namefilter, include & exclude filter, if match return true
pub fn (row Row) filter(args_ RowGetArgs) !bool {
	mut ok := false
	mut args := args_

	if args.rowname != '' {
		if args.rowname !in args.namefilter {
			args.namefilter << args.rowname
		}
	}

	if args.namefilter.len == 0 && args.includefilter.len == 0 && args.excludefilter.len == 0 {
		// this means we match all
		return true
	}

	if args.includefilter.len > 0 || args.excludefilter.len > 0 {
		tagstofilter := paramsparser.parse(row.tags)!
		ok = tagstofilter.filter_match(
			include: args.includefilter
			exclude: args.excludefilter
		)!
	}
	for name1 in args.namefilter {
		if name1.to_lower() == row.name.to_lower() {
			ok = true
		}
	}
	if ok == false {
		return false
	}

	return ok
}

pub fn (mut row Row) delete() {
	row.sheet.delete(row.name)
}
