module main

import log
import freeflowuniverse.crystallib.clients.milvus
import x.json2

pub struct Vector {
pub mut:
	title    string
	link     string
	vector   []f32
	id       ?u64
	distance ?f64
}

fn main() {
	mut logger := &log.Log{
		level: .debug
	}

	do(mut logger) or {
		logger.error('${err}')
		exit(1)
	}
}

fn do(mut logger log.Log) ! {
	client := milvus.Client{
		token: 'user:password'
	}

	collection_methods(client, mut logger)!
	vector_methods(client, mut logger)!
}

fn collection_methods(client milvus.Client, mut logger log.Log) ! {
	collection_name := 'col1'

	create_collection(client, collection_name)!
	logger.info('created collection: ${collection_name}')

	defer {
		drop_collection(client, collection_name) or { logger.error('${err}') }
		logger.info('dropped collection: ${collection_name}')
	}

	description := describe_collection(client, collection_name)!
	logger.info('collection "${collection_name}" description: ${description}')

	list := list_collections(client)!
	logger.info('collection list: ${list}')
}

fn create_collection(client milvus.Client, collection_name string) ! {
	client.create_collection(
		collection_name: collection_name
		dimension:       u16(5)
	) or { return error('failed to create collection: ${err}') }
}

fn describe_collection(client milvus.Client, collection_name string) !milvus.CollectionDescription {
	desc := client.describe_collection(collection_name: collection_name) or {
		return error('failed to describe collection: ${err}')
	}

	return desc
}

fn list_collections(client milvus.Client) ![]string {
	list := client.list_collections() or { return error('failed to list collections: ${err}') }
	return list
}

fn drop_collection(client milvus.Client, collection_name string) ! {
	client.drop_collection(collection_name: collection_name) or {
		return error('failed to drop collection: ${err}')
	}
}

fn vector_methods(client milvus.Client, mut logger log.Log) ! {
	collection_name := 'col2'

	create_collection(client, collection_name)!
	logger.info('created collection: ${collection_name}')

	defer {
		drop_collection(client, collection_name) or { logger.error('${err}') }
		logger.info('dropped collection: ${collection_name}')
	}

	insert_count := insert_vector(client, collection_name)!
	logger.info('insert ${insert_count} vectors')

	query_result := query_vector(client, collection_name)!
	logger.info('vector query result: ${query_result}')

	search_result := search_vector(client, collection_name)!
	logger.info('vector search result: ${search_result}')

	for vector in search_result {
		if id := vector.id {
			get_vector_result := get_vector(client, collection_name, id)!
			logger.info('get vector result: ${get_vector_result}')

			client.delete_vector(collection_name: collection_name, id: id) or {
				return error('failed to delete vector: ${err}')
			}
			logger.info('deleted vector with id ${id}')
		}
	}
}

fn insert_vector(client milvus.Client, collection_name string) !u32 {
	data := [
		Vector{
			title:  'hamada'
			link:   'google.com'
			vector: [f32(0.23254494), 0.01374953, 0.88497432, 0.05292784, 0.02204868] // the number of elements has to match the collection's dimension
		},
	]

	inserted_vectors := client.insert_vector(collection_name: collection_name, data: data) or {
		return error('failed to insert vector: ${err}')
	}

	return inserted_vectors
}

fn query_vector(client milvus.Client, collection_name string) ![]Vector {
	query_res := client.query_vector(
		collection_name: collection_name
		filter:          'link in ["google.com"]'
		output_fields:   ['id', 'title']
	) or { return error('failed to query vectors: ${err}') }

	return decode_multiple_vectors(query_res)
}

fn search_vector(client milvus.Client, collection_name string) ![]Vector {
	search_res := client.search_vector(
		collection_name: collection_name
		filter:          'link in ["google.com"]'
		vector:          [f32(0.23254494), 0.01374953, 0.88497432, 0.05292784, 0.02204868]
		output_fields:   ['id', 'title', 'link', 'vector']
	) or { return error('failed to search for vector: ${err}') }

	return decode_multiple_vectors(search_res)
}

fn decode_multiple_vectors(data json2.Any) []Vector {
	mut vectors := []Vector{}
	for a in data.arr() {
		vectors << decode_single_vector(a)
	}
	return vectors
}

fn upsert_vector(client milvus.Client, collection_name string) !milvus.UpsertVectorResponse {
	data := []json2.Any{}
	upserted_vectors := client.upsert_vector(
		collection_name: collection_name
		data:            data
	) or { return error('failed to upsert vector: ${err}') }
	return upserted_vectors
}

fn get_vector(client milvus.Client, collection_name string, id u64) ![]Vector {
	get_vector_res := client.get_vector(
		collection_name: collection_name
		id:              id
		output_fields:   [
			'id',
			'title',
			'link',
			'vector',
		]
	) or { return error('failed to get vector: ${err}') }

	return decode_multiple_vectors(get_vector_res)
}

fn decode_single_vector(data json2.Any) Vector {
	mp := data.as_map()
	mut vector := Vector{}

	title := mp['title'] or { '' }
	vector.title = title.str()

	link := mp['link'] or { '' }
	vector.link = link.str()

	id := mp['id'] or { 0 }
	vector.id = id.u64()

	distance := mp['distance'] or { 0 }
	vector.distance = distance.f64()

	vector_array := mp['vector'] or { []json2.Any{} }
	for val in vector_array.arr() {
		vector.vector << val.f32()
	}

	return vector
}
