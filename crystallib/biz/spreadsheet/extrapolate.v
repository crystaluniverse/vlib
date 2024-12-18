module spreadsheet

import freeflowuniverse.crystallib.ui.console

// smartstring is something like 3:2,10:5 means end month 3 we start with 2, it grows to 5 on end month 10 .
// the cells out of the mentioned ranges are not filled if they are already set .
// the cells which are empty at start of row will become 0 .
// the cells which are empty at the back will just be same value as the last one .
// currencies can be used e.g. 3:10usd,20:30aed (so we can even mix) .
// first cell is 1, the start is 0 (month 0) .
// if the smartstr, is empty then will use existing values in the row to extra/intra polate, the empty values will be filled in
pub fn (mut r Row) extrapolate(smartstr string) ! {
	// put the values in the row
	// console.print_debug("extrapolate: ${smartstr}")
	for mut part in smartstr.split(',') {
		part = part.trim_space()
		if part.contains(':') {
			splitted := part.split(':')
			if splitted.len != 2 {
				return error("smartextrapolate needs '3:2,10:5' as format, now ${smartstr} ")
			}
			mut x := splitted[0].int()
			if x < 0 {
				return error('Cannot do smartstr, because the X is out of scope.\n${smartstr}')
			}
			if x > r.sheet.nrcol - 1 {
				x = r.sheet.nrcol - 1
			}
			r.cells[x].set(splitted[1])!
		}
	}

	mut xlast := 0 // remembers where there was last non empty value
	mut has_previous_value := false
	mut xlastval := 0.0 // the value at that position
	mut xlastwidth := 0 // need to know how fast to go up from the xlast to xnew
	mut xnewval := 0.0
	// console.print_debug(r)
	for x in 0 .. r.cells.len {
		// console.print_debug("$x empty:${r.cells[x].empty} xlastwidth:$xlastwidth xlastval:$xlastval xlast:$xlast")
		if r.cells[x].empty && !has_previous_value {
			continue
		}
		has_previous_value = true
		if r.cells[x].empty == false && xlastwidth == 0 {
			// we get new value, just go to next
			xlast = x
			xlastval = r.cells[x].val
			xlastwidth = 0
			// console.print_debug(" lastval:$xlastval")
			continue // no need to do anything
		}
		// if we get here we get an empty after having a non empty before
		xlastwidth += 1
		if r.cells[x].empty == false {
			// now we find the next one not being empty so we need to do the interpolation
			xnewval = r.cells[x].val
			// now we need to walk over the inbetween and set the values
			yincr := (xnewval - xlastval) / xlastwidth
			mut yy := xlastval
			// console.print_debug(" yincr:$yincr")
			for xx in (xlast + 1) .. x {
				yy += yincr
				r.cells[xx].set('${yy:.2f}')!
			}
			xlast = x
			xlastval = xnewval
			xlastwidth = 0
			xnewval = 0.0
		}
	}
	// console.print_debug("ROW1:$r")

	// now fill in the last ones
	xlastval = 0.0
	for x in 0 .. r.cells.len {
		if r.cells[x].empty == false {
			xlastval = r.cells[x].val
			continue
		}
		r.cells[x].set('${xlastval:.2f}')!
	}

	// console.print_debug("ROW:$r")
	// if true{panic("s")}
}

// something like 3:2,10:5 means end month 3 we set 2, month 10 5
// there i no interpolation, all other fields are set on 0
pub fn (mut r Row) smartfill(smartstr string) ! {
	// console.print_debug("smartfill: ${smartstr}")
	for mut part in smartstr.split(',') {
		part = part.trim_space()
		if part.contains(':') {
			splitted := part.split(':')
			if splitted.len != 2 {
				return error("smartextrapolate needs '3:2,10:5' as format, now ${smartstr} ")
			}
			x := splitted[0].int()
			if x < 0 {
				return error('Cannot do smartstr, because the X is out of scope.\n${smartstr}')
			}
			if x > r.sheet.nrcol {
				return error('Cannot do smartstr, because the X is out of scope, needs to be 1+.\n${smartstr}')
			}
			r.cells[x].set(splitted[1])!
		} else {
			r.cells[0].set(part)!
		}
	}
	for x in 0 .. r.cells.len {
		if r.cells[x].empty {
			r.cells[x].set('0.0')!
		}
	}
}
