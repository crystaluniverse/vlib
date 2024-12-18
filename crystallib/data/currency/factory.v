module currency

__global (
	currencies shared map[string]Currency
)

fn check() {
	if currencies.len == 0 {
		refresh() or { panic(err) }
	}
}

// get a currency object based on the name
pub fn get(name_ string) !Currency {
	mut name := name_.to_upper().trim_space()
	check()
	rlock currencies {
		return currencies[name] or {
			println(currencies)
			return error('Could not find currency ${name}')
		}
	}
	panic('bug')
}

pub fn set_default(name_ string, val f64) ! {
	check()
	mut name := name_.to_upper().trim_space()
	lock currencies {
		currencies[name] = Currency{
			name:   name
			usdval: val
		}
	}
}
