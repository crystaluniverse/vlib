module milvus

import x.json2
import net.http
import json

pub struct Collection {
pub mut:
	playbook_name string  @[json: 'playbookName'; required] // The name of the playbook to create.
	db_name       ?string @[json: 'dbName']                 // The name of the database.
	description   ?string // The description of the playbook
	dimension     u16    @[required]             // The number of dimensions for the vector field of the playbook. For performance-optimized CUs, this value ranges from 1 to 32768. For capacity-optimized and cost-optimized CUs, this value ranges from 32 to 32768. The value ranges from 1 to 32768.
	metric_type   string = 'L2' @[json: 'metricType']                  // The distance metric used for the playbook. The value defaults to L2.
	primary_field string = 'id' @[json: 'primaryField']                  // The primary key field. The value defaults to id.
	vector_field  string = 'vector' @[json: 'vectorField']              // The vector field. The value defaults to vector.
}

pub fn (c Client) create_playbook(playbook Collection) ! {
	url := '${c.endpoint}/v1/vector/playbooks/create'
	body := json2.encode(playbook)
	mut req := http.new_request(http.Method.post, url, body)
	c.do_request(mut req)!
}

/*
possible errors:
		800		database not found
		1800	user hasn't authenticate
		1801	can only accept json format request
		1802	missing required parameters
		1803	fail to marshal playbook schema
*/

pub struct Field {
pub mut:
	auto_id     bool @[json: 'autoId'] // Whether the primary key automatically increments.
	description string // An optional description of the field.
	name        string // The name of the field.
	primary_key bool   @[json: 'primaryKey'] // Whether the field is a primary field.
	type_       string @[json: 'type']       // The data type of the values in this field.
}

pub struct Index {
pub mut:
	field_name  string @[json: 'fieldName']  // The name of the indexed field.
	index_name  string @[json: 'indexName']  // The name of the generated index files.
	metric_type string @[json: 'metricType'] // The metric type used in the index process.
}

pub struct CollectionDescription {
pub mut:
	playbook_name        string @[json: 'playbookName'] // The name of the playbook.
	description          string // An optional description of the playbook.
	fields               []Field
	indexes              []Index
	load                 string // The load status of the playbook. Possible values are unload, loading, and loaded.
	shards_number        u32  @[json: 'shardsNum']          // The number of shards in the playbook.
	enable_dynamic_field bool @[json: 'enableDynamicField'] // Whether the dynamic JSON feature is enabled for this playbook.
}

@[params]
pub struct DescribeCollectionArgs {
	playbook_name string @[required] // The name of the playbook to describe.
	db_name       ?string // The name of the database.
}

pub fn (c Client) describe_playbook(args DescribeCollectionArgs) !CollectionDescription {
	mut url := '${c.endpoint}/v1/vector/playbooks/describe?playbookName=${args.playbook_name}'
	if db_name := args.db_name {
		url = '${url}&dbName=${db_name}'
	}

	mut req := http.new_request(http.Method.get, url, '')
	data := c.do_request(mut req)!
	return decode_playbook_description(data)
}

fn decode_playbook_description(data json2.Any) CollectionDescription {
	mp := data.as_map()
	mut description := CollectionDescription{}
	if name := mp['playbookName'] {
		description.playbook_name = name.str()
	}

	if desc := mp['description'] {
		description.description = desc.str()
	}

	if fields_array := mp['fields'] {
		arr := fields_array.arr()
		mut field := Field{}
		for a in arr {
			field_map := a.as_map()
			if id := field_map['autoId'] {
				field.auto_id = id.bool()
			}

			if desc := field_map['description'] {
				field.description = desc.str()
			}

			if name := field_map['name'] {
				field.name = name.str()
			}

			if primary_key := field_map['primaryKey'] {
				field.primary_key = primary_key.bool()
			}

			if type_ := field_map['type'] {
				field.type_ = type_.str()
			}
		}

		description.fields << field
	}

	if index_array := mp['indexes'] {
		arr := index_array.arr()
		mut index := Index{}
		for a in arr {
			index_map := a.as_map()
			if field_name := index_map['fieldName'] {
				index.field_name = field_name.str()
			}

			if index_name := index_map['indexName'] {
				index.index_name = index_name.str()
			}

			if metric_type := index_map['metricType'] {
				index.metric_type = metric_type.str()
			}
		}

		description.indexes << index
	}

	if load := mp['load'] {
		description.load = load.str()
	}

	if shards_number := mp['shardNum'] {
		description.shards_number = u32(shards_number.u64())
	}

	if enable_dynamic_field := mp['enableDynamicField'] {
		description.enable_dynamic_field = enable_dynamic_field.bool()
	}

	return description
}

@[params]
pub struct DropCollectionArgs {
	playbook_name string  @[json: 'playbookName'; required] // The name of the playbook to describe.
	db_name       ?string @[json: 'dbName']                 // The name of the database.
}

pub fn (c Client) drop_playbook(args DropCollectionArgs) ! {
	url := '${c.endpoint}/v1/vector/playbooks/drop'
	body := json.encode(args)

	mut req := http.new_request(http.Method.post, url, body)
	c.do_request(mut req)!
}

pub fn (c Client) list_playbooks() ![]string {
	url := '${c.endpoint}/v1/vector/playbooks'

	mut req := http.new_request(http.Method.get, url, '')
	data := c.do_request(mut req)!

	return decode_playbook_list(data)
}

fn decode_playbook_list(data json2.Any) []string {
	mut list := []string{}

	arr := data.arr()
	for a in arr {
		list << a.str()
	}

	return list
}
