module pet_store_actor




	pub fn cmd() Command {
		mut cmd := Command{
			name: 'pet_store'
			usage: ''
			description: 'A sample API for a pet store'
			execute: cmd_execute
		}
			
		mut cmd_list_pets := Command{
			sort_flags: true
			name: 'list_pets'
			execute: cmd_list_pets_execute
			description: 'List all pets'
		}
	
		
		mut cmd_create_pet := Command{
			sort_flags: true
			name: 'create_pet'
			execute: cmd_create_pet_execute
			description: 'Create a new pet'
		}
	
		
		mut cmd_get_pet := Command{
			sort_flags: true
			name: 'get_pet'
			execute: cmd_get_pet_execute
			description: 'Get a pet by ID'
		}
	
		
		mut cmd_delete_pet := Command{
			sort_flags: true
			name: 'delete_pet'
			execute: cmd_delete_pet_execute
			description: 'Delete a pet by ID'
		}
	
		
		mut cmd_list_orders := Command{
			sort_flags: true
			name: 'list_orders'
			execute: cmd_list_orders_execute
			description: 'List all orders'
		}
	
		
		mut cmd_get_order := Command{
			sort_flags: true
			name: 'get_order'
			execute: cmd_get_order_execute
			description: 'Get an order by ID'
		}
	
		
		mut cmd_delete_order := Command{
			sort_flags: true
			name: 'delete_order'
			execute: cmd_delete_order_execute
			description: 'Delete an order by ID'
		}
	
		
		mut cmd_create_user := Command{
			sort_flags: true
			name: 'create_user'
			execute: cmd_create_user_execute
			description: 'Create a user'
		}
	

		fn cmd_listPets(cmd Command) ! {
			result := pet_store.listPets()!
			console.print_stdout(result.str())
		}
	

		fn cmd_createPet(cmd Command) ! {
			result := pet_store.createPet()!
			console.print_stdout(result.str())
		}
	

		fn cmd_getPet(cmd Command) ! {
			result := pet_store.getPet()!
			console.print_stdout(result.str())
		}
	

		fn cmd_deletePet(cmd Command) ! {
			result := pet_store.deletePet()!
			console.print_stdout(result.str())
		}
	

		fn cmd_listOrders(cmd Command) ! {
			result := pet_store.listOrders()!
			console.print_stdout(result.str())
		}
	

		fn cmd_getOrder(cmd Command) ! {
			result := pet_store.getOrder()!
			console.print_stdout(result.str())
		}
	

		fn cmd_deleteOrder(cmd Command) ! {
			result := pet_store.deleteOrder()!
			console.print_stdout(result.str())
		}
	

		fn cmd_createUser(cmd Command) ! {
			result := pet_store.createUser()!
			console.print_stdout(result.str())
		}
	