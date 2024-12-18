module spreadsheet

import math

@[params]
pub struct RowRecurringArgs {
	RowCopyArgs
pub mut:
	nrmonths    int = 60
	delaymonths int // how many months should we delay the output
}

pub fn (mut r Row) recurring(args_ RowRecurringArgs) !&Row {
	mut args := args_
	if args.name == '' {
		args.name = r.name
		r.sheet.delete(r.name)
	}

	if args.nrmonths < 5 {
		return error('nrmonths should be at least 5 for recurring, args:${args} \non ${r}')
	}

	mut row_result := r.copy(
		name:          args.name
		tags:          args.tags
		descr:         args.descr
		subgroup:      args.subgroup
		aggregatetype: args.aggregatetype
	)!

	for x in 0 .. r.sheet.nrcol {
		mut aggregated := 0.0
		startnr := math.max(0, x - args.nrmonths)

		for x2 in startnr .. x + 1 {
			// println("${startnr}-${x}  ${x2}:${r.cells[x2].val}")
			aggregated += r.cells[x2].val // go back max nrmonths months and aggregate it all
		}
		row_result.cells[x].empty = false
		row_result.cells[x].val = aggregated
	}
	if args.delaymonths > 0 {
		row_result.delay(args.delaymonths)!
	}
	return row_result
}
