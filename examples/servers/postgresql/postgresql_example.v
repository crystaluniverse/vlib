module main3

import pg

@[table: 'customers']
struct Customer {
	id          int    @[primary; sql: serial] // a field named `id` of integer type must be the first field
	name        string @[nonull]
	description string
	nr_orders   int
	country     string @[nonull]
}

fn do() ? {
	db := pg.connect(host: 'localhost', user: 'postgres', dbname: 'postgres')?

	sql db {
		drop table Customer
	}

	sql db {
		create table Customer
	}
	for i in 0 .. 99000 {
		new_customer := Customer{
			name:        'Bob${i}'
			description: 'Bosssssb${i}'
			nr_orders:   i
		}
		sql db {
			insert new_customer into Customer
		}
	}

	customer2 := sql db {
		select from Customer where id == 5
	}
	println(customer2)
}

fn main() {
	do() or { panic(err) }
}
