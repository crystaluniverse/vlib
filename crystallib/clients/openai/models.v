module openai

import json

pub struct Model {
pub mut:
	id         string
	created    int
	object     string
	owned_by   string
	root       string
	parent     string
	permission []ModelPermission
}

pub struct ModelPermission {
pub mut:
	id                   string
	created              int
	object               string
	allow_create_engine  bool
	allow_sampling       bool
	allow_logprobs       bool
	allow_search_indices bool
	allow_view           bool
	allow_fine_tuning    bool
	organization         string
	is_blocking          bool
}

pub struct Models {
pub mut:
	data []Model
}

// list current models available in Open AI
pub fn (mut f OpenAIClient[Config]) list_models() !Models {
	mut conn := f.connection()!
	r := conn.get(prefix: 'models')!
	return json.decode(Models, r)!
}

// returns details of a model using the model id
pub fn (mut f OpenAIClient[Config]) get_model(model string) !Model {
	mut conn := f.connection()!
	r := conn.get(prefix: 'models/' + model)!
	return json.decode(Model, r)!
}
