module jsonschema

type Items = SchemaRef | []SchemaRef

pub type SchemaRef = Reference | Schema

pub struct Reference {
pub:
	ref string @[json: 'ref']
}

type Number = int

// https://json-schema.org/draft-07/json-schema-release-notes.html
pub struct Schema {
pub mut:
	schema                string @[json: 'schema']
	id                    string @[json: 'id']
	title                 string
	description           string
	typ                   string @[json: 'type']
	properties            map[string]SchemaRef
	additional_properties SchemaRef @[json: 'additionalProperties']
	required              []string
	items                 Items
	defs                  map[string]SchemaRef
	one_of                []SchemaRef @[json: 'oneOf']
	format                string
	// todo: make fields optional upon the fixing of https://github.com/vlang/v/issues/18775
	// from https://git.sr.ht/~emersion/go-jsonschema/tree/master/item/schema.go
	// Validation for numbers
	multiple_of       int      @[json: 'multipleOf'; omitempty]
	maximum           int      @[omitempty]
	exclusive_maximum int      @[json: 'exclusiveMaximum'; omitempty]
	minimum           int      @[omitempty]
	exclusive_minimum int      @[json: 'exclusiveMinimum'; omitempty]
	enum_             []string @[json: 'enum'; omitempty]
}
