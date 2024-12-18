module encoderhero

import time
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.core.texttools

struct TestStruct {
	id   int
	name string
}

const blank_script = '!!define.test_struct'
const full_script = '!!define.test_struct id: 42 name: testobject'
const invalid_script = '!!define.another_struct'

fn test_decode_simple() ! {
	mut object := decode[TestStruct](blank_script)!
	assert object == TestStruct{}

	object = decode[TestStruct](full_script)!
	assert object == TestStruct{
		id:   42
		name: 'testobject'
	}

	object = decode[TestStruct](invalid_script) or {
		assert true
		TestStruct{}
	}
}

struct ChildStruct {
	text   string
	number int
}

struct ComplexStruct {
	id    int
	name  string
	child ChildStruct
}

const blank_complex = '!!define.complex_struct'
const partial_complex = '!!define.complex_struct id: 42 name: testcomplex'
const full_complex = '!!define.complex_struct id: 42 name: testobject
!!define.complex_struct.child text: child_text number: 24
'

fn test_decode_complex() ! {
	mut object := decode[ComplexStruct](blank_complex)!
	assert object == ComplexStruct{}

	object = decode[ComplexStruct](partial_complex)!
	assert object == ComplexStruct{
		id:   42
		name: 'testcomplex'
	}

	object = decode[ComplexStruct](full_complex) or {
		assert true
		ComplexStruct{}
	}
}

pub struct Base {
	id int
	// remarks []Remark TODO: add support
}

pub struct Remark {
	text string
}

pub struct Person {
	Base
mut:
	name     string
	age      ?int
	birthday time.Time
	deathday time.Time
	car      Car
	profiles []Profile
}

pub struct Car {
	name      string
	year      int
	insurance Insurance
}

pub struct Insurance {
	provider   string
	expiration time.Time
}

pub struct Profile {
	platform string
	url      string
}

const person_heroscript = "
!!define.person id:1 name:Bob age:21 birthday:'2012-12-12 00:00:00'
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

fn test_decode() ! {
	mut object := decode[Person]('')!
	assert object == Person{}

	object = decode[Person](person_heroscript)!
	assert object == person

	// object = decode[ComplexStruct](full_complex) or {
	// 	assert true
	// 	ComplexStruct{}
	// }
}
