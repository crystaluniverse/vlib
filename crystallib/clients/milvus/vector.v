module milvus

import net.http
import x.json2

type ID = []string | []u64 | string | u64

@[params]
pub struct VectorDeleteArgs {
	db_name       ?string @[json: 'dbName']                 // The name of the database.
	playbook_name string  @[json: 'playbookName'; required] // The name of the playbook to which this operation applies.
	id            ID      @[required]                       // An array of ID/IDs of the entities to be retrieved. This could be a string, list of strings, or list of integers, depending on the id type.
}

pub fn (c Client) delete_vector(args VectorDeleteArgs) ! {
	url := '${c.endpoint}/v1/vector/delete'
	body := json2.encode(args)

	mut req := http.new_request(http.Method.post, url, body)
	c.do_request(mut req)!
}

@[params]
pub struct VectorGetArgs {
	db_name       ?string   @[json: 'dbName']                 // The name of the database.
	playbook_name string    @[json: 'playbookName'; required] // The name of the playbook to which this operation applies.
	output_fields ?[]string @[json: 'outputFields']           // An array of fields to return along with the search results.
	id            ID        @[required]                       // An array of ID/IDs of the entities to be retrieved. This could be a string, list of strings, or list of integers, depending on the id type.
}

pub fn (c Client) get_vector(args VectorGetArgs) !json2.Any {
	url := '${c.endpoint}/v1/vector/get'
	body := json2.encode(args)

	mut req := http.new_request(http.Method.post, url, body)
	data := c.do_request(mut req)!
	return data
}

@[params]
pub struct InsertVectorArgs[T] {
	db_name       ?string @[json: 'dbName']                 // The name of the database.
	playbook_name string  @[json: 'playbookName'; required] // The name of the playbook to which entities will be inserted.
	data          []T     @[required]                       // An array of entity objects. Note that the keys in an entity object should match the playbook schema
}

struct InsertVectorResponse {
	insert_count u32 @[json: 'insertCount']
}

pub fn (c Client) insert_vector[T](args InsertVectorArgs[T]) !u32 {
	url := '${c.endpoint}/v1/vector/insert'
	body := json2.encode(args)

	mut req := http.new_request(http.Method.post, url, body)
	data := c.do_request(mut req)!

	return decode_insert_vector(data)
}

fn decode_insert_vector(data json2.Any) !u32 {
	mp := data.as_map()
	count := mp['insertCount'] or { return error('invalid response data: ${data}') }
	return u32(count.u64())
}

@[params]
pub struct QueryVectorArgs {
	db_name       ?string @[json: 'dbName']                 // The name of the database.
	playbook_name string  @[json: 'playbookName'; required] // The name of the playbook to which this operation applies.
	filter        string  @[required]                       // The filter used to find matches for the search.
	limit         u8 = 100 // The maximum number of entities to return. The sum of this value and that of offset should be less than 16384. The value ranges from 1 to 100.
	offset        ?u16 // The number of entities to skip in the search results. The sum of this value and that of limit should be less than 16384. The maximum value is 16384.
	output_fields []string @[json: 'outputFields'] // An array of fields to return along with the search results.
}

pub fn (c Client) query_vector(args QueryVectorArgs) !json2.Any {
	url := '${c.endpoint}/v1/vector/query'
	body := json2.encode(args)

	mut req := http.new_request(http.Method.post, url, body)
	data := c.do_request(mut req)!
	return data
}

@[params]
pub struct SearchVectorArgs {
	db_name       ?string @[json: 'dbName']                 // The name of the database.
	playbook_name string  @[json: 'playbookName'; required] // The name of the playbook to which this operation applies.
	filter        string  @[required]                       // The filter used to find matches for the search.
	limit         u8 = 100 // The maximum number of entities to return. The sum of this value and that of offset should be less than 16384. The value ranges from 1 to 100.
	offset        ?u16 // The number of entities to skip in the search results. The sum of this value and that of limit should be less than 16384. The maximum value is 16384.
	output_fields []string @[json: 'outputFields'] // An array of fields to return along with the search results.
	params        ?SearchParams
	vector        []f32 @[required] // The query vector in the form of a list of floating numbers.
}

pub struct SearchParams {
	radius       f64 // The angle where the vector with the least similarity resides.
	range_filter f64 // Used in combination to filter vector field values whose similarity to the query vector falls into a specific range.
}

pub fn (c Client) search_vector(args SearchVectorArgs) !json2.Any {
	url := '${c.endpoint}/v1/vector/search'
	body := json2.encode(args)

	mut req := http.new_request(http.Method.post, url, body)
	mut data := c.do_request(mut req)!

	return data
}

@[params]
pub struct UpsertVectorArgs {
	db_name       ?string     @[json: 'dbName']                 // The name of the database.
	playbook_name string      @[json: 'playbookName'; required] // The name of the playbook to which entities will be inserted.
	data          []json2.Any @[required]                       // An array of entity objects. Note that the keys in an entity object should match the playbook schema
}

pub struct UpsertVectorResponse {
	upsert_count u32  @[json: 'upsertCount'] // The number of inserted entities.
	upsert_ids   []ID @[json: 'upsertIds']   // An array of the IDs of inserted entities.
}

pub fn (c Client) upsert_vector(args UpsertVectorArgs) !UpsertVectorResponse {
	url := '${c.endpoint}/v1/vector/upsert'
	body := json2.encode(args)

	mut req := http.new_request(http.Method.post, url, body)
	data := c.do_request(mut req)!
	return decode_upsert_vector_data(data)
}

fn decode_upsert_vector_data(data json2.Any) !UpsertVectorResponse {
	mp := data.as_map()
	count := mp['upsertCount'] or {
		return error('invalid response data: missing "upsertCount" field: ${data}')
	}
	mut ids := []ID{}

	upsert_ids := mp['upsertIds'] or {
		return error('invalid response data: missing "upsertIds" field: ${data}')
	}
	for a in upsert_ids.arr() {
		ids << a.u64()
	}

	return UpsertVectorResponse{
		upsert_count: u32(count.u64())
		upsert_ids:   ids
	}
}
