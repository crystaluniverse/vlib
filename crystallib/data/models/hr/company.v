module hr

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook

pub struct Company {
pub mut:
	name        string
	country     &Country
	description string
	purpose     string
	address     string
	shares      ?CompanyShares
}

pub struct CompanyShares {
pub mut:
	number_of_shares u64
	share_value      string
	valuation_date   string
}

fn (mut self HRData) add_companies(mut session base.Session) {
	for mut action in session.plbook.find(filter: 'cos:company_define') or { [] } {
		company := self.extract_company_information(mut action) or {
			self.errors << 'invalid company information: ${err}'
			continue
		}

		if _ := self.companies[company.name] {
			self.errors << 'redefinition of company ${company.name}'
			continue
		}

		self.companies[company.name] = company
	}
}

fn (mut self HRData) extract_company_information(mut action playbook.Action) !Company {
	mut p := action.params
	name := p.get('name')!
	purpose := p.get_default('purpose', '')!.trim_space()
	description := p.get_default('description', '')!.trim_space()
	country_str := p.get('country')!
	country_id := country_id_from_str(country_str)!
	mut country := self.countries[country_id] or {
		return error('missing definition of country "${country_str}"')
	}

	address := p.get_default('address', '')!.trim_space()

	return Company{
		name: name
		country: &country
		description: if description != '' { description } else { none }
		purpose: if purpose != '' { purpose } else { none }
		address: if address != '' { address } else { none }
	}
}
