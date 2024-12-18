module budget

import freeflowuniverse.protocolme.people
import freeflowuniverse.protocolme.models.backoffice.finance
import freeflowuniverse.protocolme.models.backoffice.people
import freeflowuniverse.crystallib.timetools { time_from_string }

// budget_item_person
// This file deals with a person's budget line item

@[heap]
pub struct BudgetItemPerson {
	BudgetItemBase
pub mut:
	person               &people.Person
	salary_cost_month    &finance.Amount
	car_cost_month       &finance.Amount
	travel_cost_month    &finance.Amount
	other_cost_month     &finance.Amount
	salary_increase_year int                     // is in percent e.g. 10 is 10% per year, 0 is not planned
	bonus_months         map[int]&finance.Amount // if bonuses need to be added per month, is done per year e.g. on month 10 is 1000 USD bonus
}

pub struct PersonAddArgs {
	country              &people.Country
	person               &people.Person
	remark               string
	start                string
	stop                 string
	salary_cost_month    string
	car_cost_month       string
	travel_cost_month    string
	other_cost_month     string
	salary_increase_year int            // is in percent e.g. 10 is 10% per year, 0 is not planned
	bonus_months         map[int]string // if bonuses need to be added per month, is done per year e.g. on month 10 is 1000 USD bonus
}

//+1d, (d,h,m,y) or yyyy:mm:dd
//? how do you add error handling into this?
pub fn (mut budget Budget) person_add(args PersonAddArgs) !&BudgetItemPerson {
	// parses the bonus_months field
	mut bonus_months := map[int]&finance.Amount{}
	for key, value in args.bonus_months {
		bonus_months[key] = finance.amount_get(value)
	}

	// parse cost strings
	salary_cost_month := finance.amount_get(args.salary_cost_month)
	car_cost_month := finance.amount_get(args.car_cost_month)
	travel_cost_month := finance.amount_get(args.travel_cost_month)
	other_cost_month := finance.amount_get(args.other_cost_month)

	// get total cost
	total_cost := finance.add_amounts([salary_cost_month, car_cost_month, travel_cost_month,
		other_cost_month]) or { return error('Failed to add amounts: ${err}') }

	mut id := 1
	if budget.planning.len != 0 {
		id = budget.planning.last().id + 1
	}

	// TODO: Calculate VAT
	// TODO: More generally of finding other objects without the main data object
	mut vat_extra := finance.Amount{}
	vat_percent := args.country.vat_percent

	if args.person.person_type == .consultant {
		vat_extra = finance.Amount{
			currency: car_cost_month.currency
			val:      total_cost.val * vat_percent / 100
		}
	}

	item := BudgetItemPerson{
		id:                   id
		name:                 ('Budget for ${args.person.firstname} ${args.person.lastname}')
		remark:               args.remark
		start:                time_from_string(args.start) or {
			return error('Failed to get time from start string: ${args.start}')
		}
		stop:                 time_from_string(args.stop) or {
			return error('Failed to get time from stop string: ${args.stop}')
		}
		cost_fixed:           &total_cost
		cost_fixed_min:       &total_cost
		cost_fixed_max:       &total_cost
		country:              args.country // TODO how best to do this? enum or custom struct?
		person:               args.person
		salary_cost_month:    salary_cost_month
		car_cost_month:       car_cost_month
		travel_cost_month:    travel_cost_month
		other_cost_month:     other_cost_month
		salary_increase_year: args.salary_increase_year
		bonus_months:         bonus_months
		vat_extra:            &vat_extra
		vat_percent:          vat_percent
	}

	budget.planning << item

	return &item
}

//? should cost_fixed change every year for BudgetItemPerson
//? When do salaries increase? At the end of each year?
pub fn (mut item BudgetItemPerson) spreadsheet(year int, month int) f64 {
	// get fixed_cost
	// add bonus
	// accomodate for salary increase
	return 1
	// TODO: put calculations in here how to calculate salary of a person
}
