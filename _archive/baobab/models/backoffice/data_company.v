module backoffice

// import freeflowuniverse.backoffice.people
import freeflowuniverse.protocolme.organization
import freeflowuniverse.crystallib.core.texttools

// TODO company_add
pub fn (mut memdb MemDB) company_add(o organization.CompanyNewArgs) &organization.Company {
	mut obj := organization.Company{
		name:                 o.name
		registration_country: o.registration_country
	}
	// sets the start date of the person

	shortname := texttools.name_fix_no_underscore_no_ext(o.name)

	data.companies[shortname] = &obj
	// TODO any possible checks
	return &obj
}

// TODO company_end
/*
// Find a specific company
pub fn (mut memdb MemDB) company_find(company_name string) ?&organization.Company {
	shortname := texttools.name_fix_no_underscore_no_ext(company_name)

	if shortname in data.companies {
		return data.companies[shortname]
	}
	return error('Could not find company with name: $shortname')
}
*/
// TODO: if only return 1 then is get not find
