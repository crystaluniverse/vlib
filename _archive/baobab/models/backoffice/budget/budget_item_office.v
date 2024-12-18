module budget

import freeflowuniverse.protocolme.models.backoffice.finance
import freeflowuniverse.protocolme.models.backoffice.people
import freeflowuniverse.crystallib.timetools { time_from_string }

// budget_item_person
// This file deals with a person's budget line item

@[heap]
pub struct BudgetItemOffice {
	BudgetItemBase
pub mut:
	office_rent       &finance.Amount
	food              &finance.Amount
	utilities         &finance.Amount
	insurance         &finance.Amount
	accomodation_rent &finance.Amount
	office_supplies   &finance.Amount
}

pub struct OfficeAddArgs {
	name              string
	country           &people.Country
	remark            string
	start             string
	stop              string
	office_rent       string
	food              string
	utilities         string
	insurance         string
	accomodation_rent string
	office_supplies   string
}

//+1d, (d,h,m,y) or yyyy:mm:dd
//? how do you add error handling into this?
pub fn (mut budget Budget) office_add(args OfficeAddArgs) !&BudgetItemOffice {
	// parse cost strings
	office_rent := finance.amount_get(args.office_rent)
	food := finance.amount_get(args.food)
	utilities := finance.amount_get(args.utilities)
	insurance := finance.amount_get(args.insurance)
	accomodation_rent := finance.amount_get(args.accomodation_rent)
	office_supplies := finance.amount_get(args.office_supplies)

	// get total cost
	total_cost := finance.add_amounts([office_rent, food, utilities, insurance, accomodation_rent,
		office_supplies]) or { return error('Failed to add amounts: ${err}') }

	mut id := 1
	if budget.planning.len != 0 {
		id = budget.planning.last().id + 1
	}

	// TODO: Calculate VAT
	// No VAT on insurance
	vat_percent := args.country.vat_percent
	mut vat_extra := finance.Amount{
		currency: food.currency
		val:      (total_cost.val - insurance.val) * vat_percent / 100
	}

	item := BudgetItemOffice{
		id:                id
		name:              args.name
		remark:            args.remark
		start:             time_from_string(args.start) or {
			return error('Failed to get time from start string: ${args.start}')
		}
		stop:              time_from_string(args.stop) or {
			return error('Failed to get time from stop string: ${args.stop}')
		}
		cost_fixed:        &total_cost
		cost_fixed_min:    &total_cost
		cost_fixed_max:    &total_cost
		country:           args.country // TODO how best to do this? enum or custom struct?
		office_rent:       office_rent
		food:              food
		utilities:         utilities
		insurance:         insurance
		accomodation_rent: accomodation_rent
		office_supplies:   office_supplies
		vat_extra:         &vat_extra
		vat_percent:       vat_percent
	}

	budget.planning << item

	return &item
}
