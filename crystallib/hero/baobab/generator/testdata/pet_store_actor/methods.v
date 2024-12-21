module pet_store_actor



// Method for list_pets
fn (mut actor Actor) list_pets((limit int)) ! {}
// Method for create_pet
fn (mut actor Actor) create_pet() ! {}
// Method for get_pet
fn (mut actor Actor) get_pet((petId int)) ! {}
// Method for delete_pet
fn (mut actor Actor) delete_pet((petId int)) ! {}
// Method for list_orders
fn (mut actor Actor) list_orders() ! {}
// Method for get_order
fn (mut actor Actor) get_order((orderId int)) ! {}
// Method for delete_order
fn (mut actor Actor) delete_order((orderId int)) ! {}
// Method for create_user
fn (mut actor Actor) create_user() ! {}