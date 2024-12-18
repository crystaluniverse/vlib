module people

import freeflowuniverse.crystallib.baobab.models.system
// import json
// import freeflowuniverse.crystallib.data.encoder

@[heap]
pub struct Person {
	system.Base
pub mut:
	id          string // needs to be unique
	firstname   string
	lastname    string
	description string
	emails      []&Email
	tel         []&Tel
	addresses   []&Address
	start_date  system.OurTime
	end_date    system.OurTime
}

pub struct PersonNewArgs {
pub mut:
	id          string // needs to be unique
	firstname   string @[required]
	lastname    string @[required]
	description string
}

pub fn (mut m MemDB) person_new(args PersonNewArgs) ! {
	mut p := Person{
		id:          args.id
		firstname:   args.firstname
		lastname:    args.lastname
		description: args.description
	}
}

// pub fn person_json_load(data string) ?Person {
// 	if data != '' {
// 		obj := json.decode(Person, data) or {
// 			return error('Failed to decode json, error: ${err} for ${data}')
// 		}
// 		return obj
// 	}
// 	return Person{}
// }

// pub fn (mut o Person) bin_encoder() !encoder.Encoder {

// }

// pub fn (mut o Person) json() string {
// 	return json.encode(o)
// }
