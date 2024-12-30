module pet_store_actor

import freeflowuniverse.crystallib.ui.console
import cli { Command }

pub fn cmd() Command {
	mut cmd := Command{
		name:        'pet_store'
		usage:       ''
		description: 'A sample API for a pet store'
		execute:     cmd_execute
	}

	mut cmd_list_pets := Command{
		sort_flags:  true
		name:        'list_pets'
		execute:     cmd_list_pets_execute
		description: 'List all pets'
	}

	mut cmd_create_pet := Command{
		sort_flags:  true
		name:        'create_pet'
		execute:     cmd_create_pet_execute
		description: 'Create a new pet'
	}

	mut cmd_get_pet := Command{
		sort_flags:  true
		name:        'get_pet'
		execute:     cmd_get_pet_execute
		description: 'Get a pet by ID'
	}

	mut cmd_delete_pet := Command{
		sort_flags:  true
		name:        'delete_pet'
		execute:     cmd_delete_pet_execute
		description: 'Delete a pet by ID'
	}

	mut cmd_list_orders := Command{
		sort_flags:  true
		name:        'list_orders'
		execute:     cmd_list_orders_execute
		description: 'List all orders'
	}

	mut cmd_get_order := Command{
		sort_flags:  true
		name:        'get_order'
		execute:     cmd_get_order_execute
		description: 'Get an order by ID'
	}

	mut cmd_delete_order := Command{
		sort_flags:  true
		name:        'delete_order'
		execute:     cmd_delete_order_execute
		description: 'Delete an order by ID'
	}

	mut cmd_create_user := Command{
		sort_flags:  true
		name:        'create_user'
		execute:     cmd_create_user_execute
		description: 'Create a user'
	}
}

fn cmd_list_pets(cmd Command) ! {
	pet_store.list_pets()!
}

fn cmd_create_pet(cmd Command) ! {
	pet_store.create_pet()!
}

fn cmd_get_pet(cmd Command) ! {
	pet_store.get_pet()!
}

fn cmd_delete_pet(cmd Command) ! {
	pet_store.delete_pet()!
}

fn cmd_list_orders(cmd Command) ! {
	pet_store.list_orders()!
}

fn cmd_get_order(cmd Command) ! {
	pet_store.get_order()!
}

fn cmd_delete_order(cmd Command) ! {
	pet_store.delete_order()!
}

fn cmd_create_user(cmd Command) ! {
	pet_store.create_user()!
}
