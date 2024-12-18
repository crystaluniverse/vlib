module spreadsheet

import freeflowuniverse.crystallib.data.currency
import freeflowuniverse.crystallib.ui.console

fn test_sheets() {
	mut sh := sheet_new() or { panic(err) }

	mut nrnodes := sh.row_new(
		name:   'nrnodes'
		growth: '5:100,55:1000'
		tags:   'cat:nodes color:yellow urgent'
	)!
	mut curtest := sh.row_new(name: 'curtest', growth: '1:100EUR,55:1000AED,56:0')!

	mut nrnodes2 := sh.row_new(
		name:   'nrnodes2'
		growth: '5:100,55:1000,60:500'
		tags:   'cat:nodes delay color:green'
	)!

	mut nrnodes3 := sh.row_new(
		name:   'nrnodes3'
		growth: '0:100'
	)!

	mut incrementalrow := sh.row_new(name: 'incrementalrow', growth: '0:0,60:59')!

	mut smartrow := sh.row_new(name: 'oem', growth: '10:1000USD,40:2000', extrapolate: false)!

	assert smartrow.cells[8].val == 0.0
	assert smartrow.cells[10].val == 1000.0
	assert smartrow.cells[40].val == 2000.0

	console.print_debug('${nrnodes}')

	console.print_debug('${incrementalrow}')

	mut toincrement := sh.row_new(name: 'incr2', growth: '0:0,60:59')!
	inc1row := toincrement.recurring(name: 'testrecurring1', delaymonths: 0)!
	inc2row := toincrement.recurring(name: 'testrecurring2', delaymonths: 3)!

	console.print_debug('${toincrement}')

	a1 := toincrement.look_forward_avg(50, 20)!
	a2 := toincrement.look_forward_avg(12, 12)!

	// console.print_debug(a1)
	// console.print_debug(a2)

	// if true{panic("sss")}

	console.print_debug(inc1row)
	console.print_debug(inc2row)

	assert inc1row.cells[4].val == 10.0
	assert inc2row.cells[7].val == 10.0

	// if true{panic("sds")}

	// SUM

	mut res := []Row{}

	res << nrnodes.action(name: 'sum', action: .add, val: 100)!
	assert res.last().cells[1].val == nrnodes.cells[1].val + 100.0
	assert res.last().cells[30].val == nrnodes.cells[30].val + 100.0

	res << nrnodes.action(name: 'minus', action: .substract, val: 100)!
	assert res.last().cells[1].val == nrnodes.cells[1].val - 100.0
	assert res.last().cells[30].val == nrnodes.cells[30].val - 100.0

	res << nrnodes.action(name: 'sum2', action: .add, rows: [incrementalrow])!
	assert res.last().cells[20].val == nrnodes.cells[20].val + 20.0

	res << nrnodes.action(name: 'minus2', action: .substract, rows: [incrementalrow])!
	assert res.last().cells[20].val == nrnodes.cells[20].val - 20.0

	res << nrnodes.action(name: 'minus3', action: .substract, rows: [incrementalrow, incrementalrow])!
	assert res.last().cells[20].val == nrnodes.cells[20].val - 40.0

	res << nrnodes.action(name: 'max1', action: .max, rows: [incrementalrow])!
	assert res.last().cells[2].val == 2.0

	res << nrnodes3.action(name: 'max2', action: .max, val: 3.0)!
	assert res.last().cells[20].val == 100.0

	res << nrnodes3.action(name: 'max3', action: .max, val: 300.0)!
	assert res.last().cells[20].val == 300.0

	res << nrnodes3.action(name: 'min1', action: .min, val: 1.0)!
	assert res.last().cells[20].val == 1.0

	res << incrementalrow.action(name: 'aggr1', action: .aggregate, val: 1.0)!
	assert res.last().cells[3].val == 6.0

	console.print_debug(res.last())

	incrementalrow.delay(3)!
	assert incrementalrow.cells[6].val == 3

	// mut nrnodessum := nrnodes.add('nrnodessum', nrnodes2)!

	mut shyear := sh.toyear(name: 'shyear', includefilter: ['cat:nodes'])!
	mut shq := sh.toquarter(name: 'nrnodesq', includefilter: ['cat:nodes'])!

	console.print_debug(shyear)
	console.print_debug(shq)
	// r:=shq.json()!
	// console.print_debug(r)
	wiki := sh.wiki(description: 'is my description.')!
	console.print_debug(wiki)
	// panic('test1')
}

fn test_curr() {
	mut sh := sheet_new(name: 'test2') or { panic(err) }

	currency.set_default('AED', 0.25)!
	currency.set_default('EUR', 0.9)!

	mut pricetft := sh.row_new(name: 'something', growth: '0:100aed,55:1000eur')!

	console.print_debug(sh.rows['something'].cells[0])
	assert sh.rows['something']!.cells[0].val == 25.0
	assert sh.rows['something']!.cells[60 - 1].val == 900.0

	// TODO: we need to create tests for it

	console.print_debug(sh)
	panic('test1')
}
