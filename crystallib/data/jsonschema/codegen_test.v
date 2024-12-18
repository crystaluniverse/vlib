module jsonschema

import freeflowuniverse.crystallib.ui.console

fn test_encode_simple() ! {
	struct_str := '
// person struct used for test schema encoding
struct TestPerson {
	name string
	age int
}'

	schema := Schema{
		schema:      'test'
		title:       'TestPerson'
		description: 'person struct used for test schema encoding'
		typ:         'object'
		properties:  {
			'name': Schema{
				typ:         'string'
				description: 'name of the test person'
			}
			'age':  Schema{
				typ:         'integer'
				description: 'age of the test person'
			}
		}
	}
	encoded := schema.vstructs_encode()!
	assert encoded.len == 1
	assert encoded[0].trim_space() == struct_str.trim_space()
}

fn test_encode_schema_with_reference() ! {
	struct_str := '
// person struct used for test schema encoding
struct TestPerson {
	name string
	age int
	friend Friend
}'

	schema := Schema{
		schema:      'test'
		title:       'TestPerson'
		description: 'person struct used for test schema encoding'
		typ:         'object'
		properties:  {
			'name':   Schema{
				typ:         'string'
				description: 'name of the test person'
			}
			'age':    Schema{
				typ:         'integer'
				description: 'age of the test person'
			}
			'friend': Reference{
				ref: '#components/schemas/Friend'
			}
		}
	}
	encoded := schema.vstructs_encode()!
	assert encoded.len == 1
	assert encoded[0].trim_space() == struct_str.trim_space()
}

fn test_encode_recursive() ! {
	schema := Schema{
		schema:      'test'
		title:       'TestPerson'
		description: 'person struct used for test schema encoding'
		typ:         'object'
		properties:  {
			'name':   Schema{
				typ:         'string'
				description: 'name of the test person'
			}
			'age':    Schema{
				typ:         'integer'
				description: 'age of the test person'
			}
			'friend': Schema{
				title:       'TestFriend'
				typ:         'object'
				description: 'friend of the test person'
				properties:  {
					'name': Schema{
						typ:         'string'
						description: 'name of the test friend person'
					}
					'age':  Schema{
						typ:         'integer'
						description: 'age of the test friend person'
					}
				}
			}
		}
	}
	encoded := schema.vstructs_encode()!
	console.print_debug(encoded)
}
