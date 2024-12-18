module spreadsheet

pub enum RowAction {
	add // add rows
	substract
	divide
	multiply
	aggregate
	difference
	roundint
	max
	min
	reverse    //+1 becomes -1
	forwardavg // try to find 12 forward looking cells and do avg where we are
}

@[params]
pub struct RowActionArgs {
pub mut:
	name          string
	action        RowAction
	val           f64
	rows          []&Row
	tags          string
	descr         string
	subgroup      string
	aggregatetype RowAggregateType = .sum
	delaymonths   int // how many months should we delay the output
}

// add one row to the other
//
// '''
// name string							optional: if not used then row will be modified itself
// action        RowAction
// val f64								optional: if we want to e.g. multiply every cell with same val
// rows []Row							optional: a row if we want to add each val of item of row, can be more than 1
// tags string 							how to recognize a row (selection)
// aggregatetype RowAggregateType is 	unknown, sum, avg, max, min
// delaymonths int //how many months should we delay the output
// descr   string
// subgroup string
// '''
// row action is
// '''
// 	add // add rows
// 	substract
// 	divide
// 	multiply
// 	aggregate
// 	difference
// 	roundint
// 	max
// 	min
// 	reverse //+1 becomes -1
// 	forwardavg // try to find 12 forward looking cells and do avg where we are
// '''
//
pub fn (mut r Row) action(args_ RowActionArgs) !&Row {
	mut args := args_
	if args.name == '' {
		args.name = r.name
		r.sheet.delete(r.name)
	}

	mut row_result := r.copy(
		name:          args.name
		tags:          args.tags
		descr:         args.descr
		subgroup:      args.subgroup
		aggregatetype: args.aggregatetype
	)!

	mut prevval := 0.0
	for x in 0 .. r.sheet.nrcol {
		row_result.cells[x].empty = false
		row_result.cells[x].val = r.cells[x].val
		if args.rows.len > 0 {
			for r2 in args.rows {
				if args.action == .add {
					row_result.cells[x].val = row_result.cells[x].val + r2.cells[x].val
				} else if args.action == .substract {
					row_result.cells[x].val = row_result.cells[x].val - r2.cells[x].val
				} else if args.action == .multiply {
					row_result.cells[x].val = row_result.cells[x].val * r2.cells[x].val
				} else if args.action == .divide {
					row_result.cells[x].val = row_result.cells[x].val / r2.cells[x].val
				} else if args.action == .max {
					if r2.cells[x].val > row_result.cells[x].val {
						row_result.cells[x].val = r2.cells[x].val
					}
				} else if args.action == .min {
					if r2.cells[x].val < row_result.cells[x].val {
						row_result.cells[x].val = r2.cells[x].val
					}
				} else {
					return error('Action wrongly specified for ${r} with\nargs:${args}')
				}
			}
		}
		if args.val > 0.0 {
			if args.action == .add {
				row_result.cells[x].val = row_result.cells[x].val + args.val
			} else if args.action == .substract {
				row_result.cells[x].val = row_result.cells[x].val - args.val
			} else if args.action == .multiply {
				row_result.cells[x].val = row_result.cells[x].val * args.val
			} else if args.action == .divide {
				row_result.cells[x].val = row_result.cells[x].val / args.val
			} else if args.action == .aggregate {
				row_result.cells[x].val = row_result.cells[x].val + prevval
				prevval = row_result.cells[x].val
			} else if args.action == .difference {
				row_result.cells[x].val = row_result.cells[x].val - r.cells[x - 1].val
			} else if args.action == .roundint {
				row_result.cells[x].val = int(row_result.cells[x].val)
			} else if args.action == .max {
				if args.val > row_result.cells[x].val {
					row_result.cells[x].val = args.val
				}
			} else if args.action == .min {
				if args.val < row_result.cells[x].val {
					row_result.cells[x].val = args.val
				}
			} else {
				return error('Action wrongly specified for ${r} with\nargs:${args}')
			}
		}

		if args.action == .reverse {
			row_result.cells[x].val = -row_result.cells[x].val
		}
		if args.action == .forwardavg {
			a := row_result.look_forward_avg(x, 6)!
			row_result.cells[x].val = a
		}
	}
	if args.delaymonths > 0 {
		row_result.delay(args.delaymonths)!
	}
	return row_result
}

// pub fn (mut r Row) add(name string, r2 Row) !&Row {
// 	return r.action(name:name, rows:[]r2, tags:r.tags)
// }
pub fn (mut r Row) delay(monthdelay int) ! {
	mut todelay := []f64{}
	for x in 0 .. r.sheet.nrcol {
		todelay << r.cells[x].val
	}
	for x in 0 .. r.sheet.nrcol {
		if x < monthdelay {
			r.cells[x].val = 0.0
		} else {
			r.cells[x].val = todelay[x - monthdelay]
		}
	}
}
