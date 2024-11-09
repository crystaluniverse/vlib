module hr

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook

pub enum CountryID {
	zanzibar
	belgium
	egypt
}

pub struct Country {
pub mut:
	name string
	id   CountryID
}

fn country_id_from_str(str string) !CountryID {
	country := match str.to_lower() {
		'znz', 'zanzibar' { CountryID.zanzibar }
		'egypt' { CountryID.egypt }
		'belgium' { CountryID.belgium }
		else { return error('invalid country name ${str}') }
	}

	return country
}

fn (mut self HRData) add_countries(mut session base.Session) {
	for mut action in session.plbook.find(filter: 'cos:country_define') or { [] } {
		country := self.extract_country_information(mut action) or {
			self.errors << 'invalid country information: ${err}'
			continue
		}

		if _ := self.countries[country.id] {
			self.errors << 'redefinition of country ${country.name}'
			continue
		}

		self.countries[country.id] = country
	}
}

fn (mut self HRData) extract_country_information(mut action playbook.Action) !Country {
	mut p := action.params
	name := p.get('name')!

	id := country_id_from_str(name)!

	return Country{
		name: name
		id: id
	}
}
