module example_actor

pub fn (mut a ExampleActor) handle(method string, data string) !string {
	return data	
}