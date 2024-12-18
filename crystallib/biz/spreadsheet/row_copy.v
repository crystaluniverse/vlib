module spreadsheet

import math

@[params]
pub struct RowCopyArgs {
pub mut:
	name          string
	tags          string
	descr         string
	subgroup      string
	aggregatetype RowAggregateType = .sum
}

pub fn (mut r Row) copy(args_ RowCopyArgs) !&Row {
	mut row_result := r
	mut args := args_
	if args.name == '' {
		return error('name cannot be empty for copy, args:${args} \non ${r}')
	}
	if args.tags == '' {
		args.tags = r.tags
	}
	if args.descr == '' {
		args.descr = r.description
	}
	if args.subgroup == '' {
		args.subgroup = r.subgroup
	}
	if args.aggregatetype == .unknown {
		args.aggregatetype = r.aggregatetype
	}
	if args.name.len > 0 {
		mut r3 := r.sheet.row_new(
			name:          args.name
			aggregatetype: args.aggregatetype
			descr:         args.descr
			subgroup:      args.subgroup
			tags:          args.tags
		)!
		row_result = *r3
		for x in 0 .. r.sheet.nrcol {
			row_result.cells[x].empty = false
			row_result.cells[x].val = r.cells[x].val
		}
	} else {
		return error('name need to be specified:\n${args_}')
	}
	return &row_result
}
