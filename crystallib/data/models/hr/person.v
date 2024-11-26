module hr

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook

pub struct Person {
pub mut:
	username             string
	first_name           string
	last_name            string
	telephone_numbers    []string
	emails               []string
	linkedin             ?string
	github               ?string
	gitourworld          ?string
	url                  ?string
	description          ?string
	country_of_residence CountryID

	salary_outstanding ?SalaryOutstanding
	shares             ?Shares
	tokens             []Tokens
	loan_outstanding   []LoanOutstanding
	remuneration       ?Remuneration
}

pub struct SalaryOutstanding {
pub mut:
	company string
	amount  string
	comment ?string
	url     ?string
}

pub struct Shares {
pub mut:
	company string
	amount  u64
	comment string
}

pub struct Tokens {
pub mut:
	amount          u64
	wallet_address  string
	wallet_type     string
	wallet_currency string
	comment         ?string
}

pub struct LoanOutstanding {
pub mut:
	amount                string
	start_date            string
	payback_period        string
	payback_period_number u32
	comment               ?string
	url                   ?string
}

pub struct Remuneration {
pub mut:
	monthly_salary     string
	reward_pool_points u32
	car_per_month      string
	lodging_per_month  string
	travel_max         string
	travel_average     string
	expense_max        string
	expense_average    string
	payout_digital     map[string]DigitalPayout
	comment            ?string
	url                ?string
}

pub struct DigitalPayout {
pub mut:
	amount                  string
	wallet_address          string
	wallet_type             string
	wallet_currency         string
	period                  string = 'month'
	number_of_months_behind u32
}

pub struct ShareHolder {
pub mut:
	person       &Person
	company_name string
	amount       u32
	comment      ?string
}

fn (mut self HRData) add_people(mut session base.Session) {
	self.add_person_definitions(mut session)
	self.add_salary_outstandings(mut session)
	self.add_tokens(mut session)
	self.add_loan_outstandings(mut session)
	self.add_remunerations(mut session)
	self.add_share_holders(mut session)
}

fn (mut self HRData) add_share_holders(mut session base.Session) {
	for mut action in session.plbook.find(filter: 'cos:shareholding_define') or { [] } {
		share_holder := self.extract_share_holder_infomation(mut action) or {
			self.errors << 'invalid share holder information: ${err}'
			continue
		}

		self.share_holdres << share_holder
	}
}

fn (mut self HRData) extract_share_holder_infomation(mut action playbook.Action) !ShareHolder {
	mut p := action.params
	person_name := p.get('person_name')!
	mut person := self.people[person_name] or {
		return error('a person with the name ${person_name} is not defined')
	}

	compay_name := p.get('company_name')!
	amount := p.get_u32('amount')!
	comment := p.get_default('comment', '')!.trim_space()

	return ShareHolder{
		person: &person
		amount: amount
		company_name: compay_name
		comment: if comment != '' { comment } else { none }
	}
}

fn (mut self HRData) add_remunerations(mut session base.Session) {
	mut digital_payout := self.get_digital_payout(mut session)
	for mut action in session.plbook.find(filter: 'cos:remuneration') or { [] } {
		username, remuneration := self.extract_remuneration_information(mut action, digital_payout) or {
			self.errors << 'invalid remuneration information: ${err}'
			continue
		}

		if mut person := self.people[username] {
			person.remuneration = remuneration
		} else {
			self.errors << 'a person with the name ${username} is not defined'
			continue
		}
	}
}

fn (mut self HRData) get_digital_payout(mut session base.Session) map[string]DigitalPayout {
	mut digital_payout_map := map[string]DigitalPayout{}
	for mut action in session.plbook.find(filter: 'cos:payout_digital') or { [] } {
		name, digital_payout := self.extract_digital_payout_information(mut action) or {
			self.errors << 'invalid digital payout information: ${err}'
			continue
		}

		if _ := digital_payout_map[name] {
			self.errors << 'a digital payout with the same name "${name}" is already defined'
		} else {
			digital_payout_map[name] = digital_payout
		}
	}

	return digital_payout_map
}

fn (mut self HRData) extract_digital_payout_information(mut action playbook.Action) !(string, DigitalPayout) {
	mut p := action.params
	name := p.get('name')!
	amount := p.get('amount')!
	wallet_address := p.get('wallet_addr')!
	wallet_type := p.get('wallet_type')!
	wallet_currency := p.get('wallet_currency')!
	period := p.get_default('period', 'month')!
	months_behind := p.get_u32_default('nrmonths_behind', 0)!

	return name, DigitalPayout{
		amount: amount
		number_of_months_behind: months_behind
		period: period
		wallet_address: wallet_address
		wallet_currency: wallet_currency
		wallet_type: wallet_type
	}
}

fn (mut self HRData) extract_remuneration_information(mut action playbook.Action, digital_payout map[string]DigitalPayout) !(string, Remuneration) {
	mut p := action.params
	username := p.get('person_name')!
	salary_month := p.get('salary_month')!
	reward_pool_points := p.get_u32('reward_pool_points')!
	car_month := p.get_default('car_month', '')!
	lodging_month := p.get_default('lodgin_month', '')!
	travel_max := p.get_default('travel_max', '')!
	travel_avg := p.get_default('travel_avg', '')!
	expense_max := p.get_default('expense_max', '')!
	expense_avg := p.get_default('expense_avg', '')!
	comment := p.get_default('comment', '')!.trim_space()
	url := p.get_default('url', '')!.trim_space()
	payout_digital_str := p.get_default('payout_digital', '')!.split(',')
	mut payout_digital := map[string]DigitalPayout{}
	for str in payout_digital_str {
		if v := digital_payout[str] {
			payout_digital[str] = v
		} else {
			return error('missing digital payout definition "${str}"')
		}
	}

	remuneration := Remuneration{
		car_per_month: car_month
		expense_average: expense_avg
		expense_max: expense_max
		lodging_per_month: lodging_month
		monthly_salary: salary_month
		reward_pool_points: reward_pool_points
		travel_average: travel_avg
		travel_max: travel_max
		comment: if comment != '' { comment } else { none }
		url: if url != '' { url } else { none }
		payout_digital: payout_digital
	}

	return username, remuneration
}

fn (mut self HRData) add_loan_outstandings(mut session base.Session) {
	for mut action in session.plbook.find(filter: 'cos:loan_outstanding') or { [] } {
		username, loan := self.extract_loan_outstanding_information(mut action) or {
			self.errors << 'invalid loan outstanding information: ${err}'
			continue
		}

		if mut person := self.people[username] {
			person.loan_outstanding << loan
		} else {
			self.errors << 'a person with the name ${username} is not defined'
			continue
		}
	}
}

fn (mut self HRData) extract_loan_outstanding_information(mut action playbook.Action) !(string, LoanOutstanding) {
	mut p := action.params
	username := p.get('person_name')!
	amount := p.get('amount')!
	start_date := p.get('start_date')!
	payback_period := p.get('payback_period')!
	payback_period_number := p.get_u32('payback_period_nr')!
	comment := p.get_default('comment', '')!.trim_space()
	url := p.get_default('url', '')!.trim_space()

	loan := LoanOutstanding{
		amount: amount
		start_date: start_date
		payback_period: payback_period
		payback_period_number: payback_period_number
		comment: if comment != '' { comment } else { none }
		url: if url != '' { url } else { none }
	}

	return username, loan
}

fn (mut self HRData) add_tokens(mut session base.Session) {
	for mut action in session.plbook.find(filter: 'cos:tokens') or { [] } {
		username, tokens := self.extract_tokens_information(mut action) or {
			self.errors << 'invalid tokens information: ${err}'
			continue
		}

		if mut person := self.people[username] {
			person.tokens << tokens
		} else {
			self.errors << 'a person with the name ${username} is not defined'
			continue
		}
	}
}

fn (mut self HRData) extract_tokens_information(mut action playbook.Action) !(string, Tokens) {
	mut p := action.params
	username := p.get('person_name')!
	amount := p.get_u64('amount')!
	wallet_address := p.get('wallet_address')!
	wallet_type := p.get('wallet_type')!
	wallet_currency := p.get('wallet_currency')!
	comment := p.get_default('comment', '')!.trim_space()

	tokens := Tokens{
		amount: amount
		comment: if comment != '' { comment } else { none }
		wallet_address: wallet_address
		wallet_currency: wallet_currency
		wallet_type: wallet_type
	}

	return username, tokens
}

fn (mut self HRData) add_salary_outstandings(mut session base.Session) {
	for mut action in session.plbook.find(filter: 'cos:salary_outstanding') or { [] } {
		username, salary := self.extract_salary_outstanding_information(mut action) or {
			self.errors << 'invalid salary outstanding data: ${err}'
			continue
		}

		if mut person := self.people[username] {
			person.salary_outstanding = salary
		} else {
			self.errors << 'a person with the name ${username} is not defined'
		}
	}
}

fn (mut self HRData) extract_salary_outstanding_information(mut action playbook.Action) !(string, SalaryOutstanding) {
	mut p := action.params
	username := p.get('person_name')!
	company := p.get('company')!
	amount := p.get('amount')!
	comment := p.get_default('comment', '')!.trim_space()
	url := p.get_default('url', '')!.trim_space()

	salary := SalaryOutstanding{
		company: company
		amount: amount
		comment: if comment != '' { comment } else { none }
		url: if url != '' { url } else { none }
	}

	return username, salary
}

fn (mut self HRData) add_person_definitions(mut session base.Session) {
	for mut action in session.plbook.find(filter: 'cos:person_define') or { [] } {
		person := self.extract_person_information(mut action) or {
			self.errors << 'invalid person data: ${err}'
			continue
		}

		if _ := self.people[person.username] {
			self.errors << 'a person with the same name "${person.username}" is already defined'
			continue
		}

		self.people[person.username] = person
	}
}

fn (mut self HRData) extract_person_information(mut action playbook.Action) !Person {
	mut p := action.params
	username := p.get('name')!
	firstname := p.get_default('firstname', '')!
	lastname := p.get_default('lastname', '')!
	telephone_numbers_str := p.get_default('tel', '')!
	emails_str := p.get_default('email', '')!
	linkedin := p.get_default('linkedin', '')!.trim_space()
	github := p.get_default('github', '')!.trim_space()
	gitourworld := p.get_default('gitourworld', '')!.trim_space()
	url := p.get_default('url', '')!.trim_space()
	description := p.get_default('description', '')!.trim_space()
	country_of_residence_str := p.get_default('country_residence', '')!

	telephone_numbers := telephone_numbers_str.split(',')
	emails := emails_str.split(',')
	country := country_id_from_str(country_of_residence_str)!

	person := Person{
		username: username
		first_name: firstname
		last_name: lastname
		telephone_numbers: telephone_numbers
		emails: emails
		linkedin: if linkedin != '' { linkedin } else { none }
		github: if github != '' { github } else { none }
		gitourworld: if gitourworld != '' { gitourworld } else { none }
		url: if url != '' { url } else { none }
		description: if description != '' { description } else { none }
		country_of_residence: country
	}

	action.done = true

	return person
}
