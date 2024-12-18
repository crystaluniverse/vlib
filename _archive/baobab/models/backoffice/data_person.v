module backoffice

import freeflowuniverse.protocolme.people
import freeflowuniverse.crystallib.core.texttools
import time

pub fn (mut memdb MemDB) initialise_person() people.Person {
	mut new_person := people.Person{
		firstname:   ''
		lastname:    ''
		description: ''
		contact:     &people.Contact{}
		id:          ''
		person_type: .employee
	}

	return new_person
}

// add a person
//
// struct PersonNewArgs {
// 	name string
// 	title  string
//	description string
// }
pub fn (mut memdb MemDB) person_add(o people.PersonNewArgs) !&people.Person {
	// function to find latest id
	mut latest_id := 0
	for _, person in data.people {
		if person.id.int() > latest_id {
			latest_id = person.id.int()
		}
	}

	id := (latest_id + 1).str()

	person_type_ := o.person_type.to_lower()

	person_type := match person_type_ {
		'employee' { people.PersonType.employee } // TODO check if this is valid
		'consultant' { people.PersonType.consultant }
		'investor' { people.PersonType.investor }
		else { panic(error('Failed to parse inputted person_type: Please enter either employee, consultant or investor.')) }
	}

	mut obj := people.Person{
		firstname:   o.firstname
		lastname:    o.lastname
		description: o.description
		contact:     &people.Contact{} //? Is this necessary?
		id:          id
		person_type: person_type
	}
	// sets the start date of the person
	obj.start_date = time.now()

	shortname := texttools.name_fix_no_underscore_no_ext(obj.firstname) +
		texttools.name_fix_no_underscore_no_ext(obj.lastname)

	if shortname in data.people {
		return error('person with name:${obj.firstname} ${obj.lastname} already exists.')
	}
	data.people[shortname] = &obj
	// TODO any possible checks
	return &obj
}

/*
// makes a person inactive
// ARGS:
// - full_name of person string
pub fn (mut memdb MemDB) person_end(full_name string) {
	mut person := data.person_find(full_name) or {panic(err)}
	person.state = .inactive
	// TODO: remove this person from future budget items
}
*/
// find a specific person
// ARGS:
// - full_name of person string
pub fn (mut memdb MemDB) person_get(full_name string) !&people.Person {
	shortname := texttools.name_fix_no_underscore_no_ext(full_name).replace(' ', '')
	// TODO what happens if there are two identical names
	if shortname in data.people {
		return data.people[shortname]
	}
	return error('Could not find person with name: ${shortname}')
}

// TODO: create a filtering tool for people
