module pet_store_actor

// Method for list_pets
fn (mut actor PetStoreActor) list_pets(limit int) ! {}

// Method for create_pet
fn (mut actor PetStoreActor) create_pet() ! {}

// Method for get_pet
fn (mut actor PetStoreActor) get_pet(petId int) ! {}

// Method for delete_pet
fn (mut actor PetStoreActor) delete_pet(petId int) ! {}

// Method for list_orders
fn (mut actor PetStoreActor) list_orders() ! {}

// Method for get_order
fn (mut actor PetStoreActor) get_order(orderId int) ! {}

// Method for delete_order
fn (mut actor PetStoreActor) delete_order(orderId int) ! {}

// Method for create_user
fn (mut actor PetStoreActor) create_user() ! {}
