module spreadsheet

import freeflowuniverse.crystallib.data.currency

__global (
	sheets shared map[string]&Sheet
)

@[params]
pub struct SheetNewArgs {
pub mut:
	name          string = 'main'
	nrcol         int    = 60
	visualize_cur bool   = true  // if we want to show e.g. $44.4 in a cell or just 44.4
	curr          string = 'usd' // preferred currency to work with
}

// get a sheet
// has y nr of rows, each row has a name
// each row has X nr of columns which represent months
// we can do manipulations with the rows, is very useful for e.g. business planning
// params:
// 	nrcol int = 60
// 	visualize_cur bool //if we want to show e.g. $44.4 in a cell or just 44.4
pub fn sheet_new(args SheetNewArgs) !&Sheet {
	mut sh := Sheet{
		nrcol:    args.nrcol
		params:   SheetParams{
			visualize_cur: args.visualize_cur
		}
		currency: currency.get(args.curr)!
		name:     args.name
	}
	sheet_set(&sh)
	return &sh
}

// get sheet from global
pub fn sheet_get(name string) !&Sheet {
	rlock sheets {
		if name in sheets {
			return sheets[name]
		}
	}
	return error("cann't find sheet:'${name}' in global sheets")
}

// remember sheet in global
pub fn sheet_set(sh &Sheet) {
	lock sheets {
		sheets[sh.name] = sh
	}
}

pub fn sheets_keys() []string {
	rlock sheets {
		return sheets.keys()
	}
	panic('bug')
}
