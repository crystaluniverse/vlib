module budget

import freeflowuniverse.protocolme.models.backoffice.finance
import freeflowuniverse.protocolme.models.backoffice.people
import freeflowuniverse.crystallib.timetools { time_from_string }
import time

// budget_item
// This file deals with the budget item base and...

@[heap]
pub struct BudgetItemBase {
pub mut:
	// budget_item_type BudgetItemType
	id             int
	name           string
	remark         string
	country        &people.Country // This might change to enum or custom struct
	start          system.OurTime
	stop           system.OurTime
	cost_fixed     &finance.Amount // fixed monthly - USD
	cost_fixed_min &finance.Amount
	cost_fixed_max &finance.Amount
	vat_extra      &finance.Amount // auto-calculated for office and people, manual elsewhere
	vat_percent    f64             // 0 - 100
}

pub enum GenericType {
	software
	license
	other
}

pub struct BudgetItemGeneric {
	BudgetItemBase
pub mut:
	generic_type GenericType
}

pub struct ItemAddArgs {
	name         string
	remark       string
	start        string
	stop         string
	cost_month   string // fixed monthly - USD
	country      &people.Country
	generic_type string
	vat_extra    string = '0 USD'
}

//+1d, (d,h,m,y) or yyyy:mm:dd
//? how do you add error handling into this?
pub fn (mut budget Budget) item_add(args ItemAddArgs) !&BudgetItemGeneric {
	mut id := 1
	if budget.planning.len != 0 {
		id = budget.planning.last().id + 1
	}

	generic_type := match args.generic_type {
		'software' { GenericType.software }
		'license' { GenericType.license }
		'other' { GenericType.other }
		else { panic(error('Failed to parse inputted generic_type: Please enter either software, license or other.')) }
	}

	cost_fixed := finance.amount_get(args.cost_month)

	vat_extra := finance.amount_get(args.vat_extra)
	mut vat_percent := f64(0)
	if vat_extra.val != 0 {
		vat_percent = (100 * finance.amount_get(args.vat_extra).val / cost_fixed.val)
	}

	item := BudgetItemGeneric{
		id:             id
		name:           args.name
		remark:         args.remark
		start:          time_from_string(args.start) or {
			return error('Failed to get time from start string: ${args.start}')
		}
		stop:           time_from_string(args.stop) or {
			return error('Failed to get time from stop string: ${args.stop}')
		}
		cost_fixed:     cost_fixed
		cost_fixed_min: cost_fixed
		cost_fixed_max: cost_fixed
		country:        args.country
		generic_type:   generic_type
		vat_extra:      vat_extra
		vat_percent:    vat_percent
	}

	budget.planning << item

	return &item
}
