module calc

import freeflowuniverse.crystallib.currency

[params]
pub struct SheetNewArgs {
pub mut:
	name          string
	nrcol         int    = 60
	visualize_cur bool   = true // if we want to show e.g. $44.4 in a cell or just 44.4
	curr          string = 'usd' // preferred currency to work with
}

// get a sheet
// has y nr of rows, each row has a name
// each row has X nr of columns which represent months
// we can do manipulations with the rows, is very useful for e.g. business planning
// params:
// 	nrcol int = 60
// 	visualize_cur bool //if we want to show e.g. $44.4 in a cell or just 44.4
pub fn sheet_new(args_ SheetNewArgs) !Sheet {
	mut args := args_
	if args.name == '' {
		args.name = 'main'
	}
	mut cs := currency.new()!
	curr2 := cs.currency_get(args.curr)!
	mut sh := Sheet{
		nrcol: args.nrcol
		params: SheetParams{
			visualize_cur: args.visualize_cur
		}
		currencies: &cs
		currency: curr2
		name: args.name
	}
	return sh
}
