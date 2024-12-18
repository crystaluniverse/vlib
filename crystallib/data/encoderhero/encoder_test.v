module encoderhero

import freeflowuniverse.crystallib.data.paramsparser
import time
import v.reflection

struct Base {
	id      int
	remarks []Remark
}

struct Remark {
	text string
}

struct Person {
	Base
mut:
	name     string
	age      ?int = 20
	birthday time.Time
	deathday ?time.Time
	car      Car
	profiles []Profile
}

struct Car {
	name      string
	year      int
	insurance Insurance
}

struct Insurance {
	provider   string
	expiration time.Time
}

struct Profile {
	platform string
	url      string
}

const person_heroscript = "
!!define.person id:1 name:Bob birthday:'2012-12-12 00:00:00'
!!define.person.car name:'Bob\\'s car' year:2014
!!define.person.car.insurance expiration:'0000-00-00 00:00:00' provider:''

!!define.person.profile platform:Github url:github.com/example
"

const person = Person{
	id:       1
	name:     'Bob'
	age:      21
	birthday: time.new_time(
		day:   12
		month: 12
		year:  2012
	)
	car:      Car{
		name: "Bob's car"
		year: 2014
	}
	profiles: [
		Profile{
			platform: 'Github'
			url:      'github.com/example'
		},
	]
}

fn test_encode() ! {
	person_script := encode[Person](person)!
	assert person_script.trim_space() == person_heroscript.trim_space()
}
