module hr

import freeflowuniverse.crystallib.core.play

pub struct HRData {
pub mut:
	people        map[string]Person
	companies     map[string]Company
	share_holdres []ShareHolder
	countries     map[CountryID]Country
	errors        []string
}

pub fn new_from_session(mut session play.Session) !HRData {
	mut data := HRData{}

	data.add_countries(mut session)

	data.add_companies(mut session)

	data.add_people(mut session)

	return data
}