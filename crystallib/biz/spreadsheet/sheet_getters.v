module spreadsheet

import freeflowuniverse.crystallib.ui.console
import math

fn remove_empty_line(txt string) string {
	mut out := ''
	for line in txt.split_into_lines() {
		if line.trim_space() == '' {
			continue
		}
		out += '${line}\n'
	}
	return out
}

@[params]
pub struct RowGetArgs {
pub mut:
	rowname       string   // if specified then its one name
	namefilter    []string // only include the exact names as secified for the rows
	includefilter []string // to use with params filter e.g. ['location:belgium_*'] //would match all words starting with belgium
	excludefilter []string
	period_type   PeriodType // year, month, quarter
	aggregate     bool             = true // if more than 1 row matches should we aggregate or not
	aggregatetype RowAggregateType = .sum // important if used with include/exclude, because then we group
	unit          UnitType
	title         string
	title_sub     string
	size          string
	rowname_show  bool = true // show the name of the row
	descr_show    bool
	description   string
}

pub enum UnitType {
	normal
	thousand
	million
	billion
}

pub enum PeriodType {
	year
	month
	quarter
	error
}

// find rownames which match RowGetArgs
pub fn (s Sheet) rownames_get(args RowGetArgs) ![]string {
	mut res := []string{}
	for _, row in s.rows {
		if row.filter(args)! {
			res << row.name
		}
	}
	return res
}

// get one rowname, if more than 1 will fail, if 0 will fail
pub fn (s Sheet) rowname_get(args RowGetArgs) !string {
	r := s.rownames_get(args)!
	if r.len == 1 {
		return r[0]
	}
	if r.len == 0 {
		return error("Didn't find rows for ${s.name}.\n${args}")
	}
	return error('Found too many rows for ${s.name}.\n${args}')
}

// return e.g. "'Y1', 'Y2', 'Y3', 'Y4', 'Y5', 'Y6'" if year, is for header
pub fn (mut s Sheet) header_get_as_list(period_type PeriodType) ![]string {
	str := s.header_get_as_string(period_type)!
	return str.split(',')
}

// return e.g. "'Y1', 'Y2', 'Y3', 'Y4', 'Y5', 'Y6'" if year, is for header
pub fn (mut s Sheet) data_get_as_list(args RowGetArgs) ![]string {
	str := s.data_get_as_string(args)!
	return str.split(',')
}

// return e.g. "'Y1', 'Y2', 'Y3', 'Y4', 'Y5', 'Y6'" if year, is for header
pub fn (mut s Sheet) header_get_as_string(period_type PeriodType) !string {
	err_pre := "Can't get header for sheet:${s.name}\n"
	nryears := int(s.nrcol / 12)
	mut out := ''
	match period_type {
		.year {
			for i in 1 .. (nryears + 1) {
				out += "'Y${i}', "
			}
		}
		.quarter {
			for i in 1 .. (nryears * 4 + 1) {
				out += "'Q${i}', "
			}
		}
		.month {
			for i in 1 .. (12 * nryears + 1) {
				out += "'M${i}', "
			}
		}
		else {
			return error('${err_pre}Period type not well specified')
		}
	}
	out = out.trim_space().trim(',').trim_space()
	return out
}

// return the values
pub fn (mut s Sheet) data_get_as_string(args RowGetArgs) !string {
	if args.rowname == '' {
		return error('rowname needs to be specified')
	}
	nryears := 5
	err_pre := "Can't get data for sheet:${s.name} row:${args.rowname}.\n"
	mut s2 := s

	if args.period_type == .year {
		s2 = s.toyear(
			name:          args.rowname
			namefilter:    args.namefilter
			includefilter: args.includefilter
			excludefilter: args.excludefilter
		)!
	}
	if args.period_type == .quarter {
		s2 = s.toquarter(
			name:          args.rowname
			namefilter:    args.namefilter
			includefilter: args.includefilter
			excludefilter: args.excludefilter
		)!
	}
	mut out := ''

	// console.print_debug(s2.row_get(args.rowname)!)
	mut vals := s2.values_get(args.rowname)!
	if args.period_type == .year && vals.len != nryears {
		return error('${err_pre}Vals.len need to be 6, for year.\nhere:\n${vals}')
	}
	if args.period_type == .quarter && vals.len != nryears * 4 {
		return error('${err_pre}vals.len need to be 6*4, for quarter.\nhere:\n${vals}')
	}
	if args.period_type == .month && vals.len != nryears * 12 {
		return error('${err_pre}vals.len need to be 6*12, for month.\nhere:\n${vals}')
	}

	for mut val in vals {
		if args.unit == .thousand {
			val = val / 1000.0
		}
		if args.unit == .million {
			val = val / 1000000.0
		}
		if args.unit == .billion {
			val = val / 1000000000.0
		}
		out += ',${math.round_sig(val, 1)}'
	}
	return out.trim(',')
}

// use RowGetArgs to get to smaller version of sheet
pub fn (mut s Sheet) filter(args RowGetArgs) !&Sheet {
	period_months := match args.period_type {
		.year { 12 }
		.month { 1 }
		.quarter { 3 }
		else { panic('bug') }
	}

	tga := ToYearQuarterArgs{
		namefilter:    args.namefilter
		includefilter: args.includefilter
		excludefilter: args.excludefilter
		period_months: period_months
	}

	return s.tosmaller(tga)!
}
