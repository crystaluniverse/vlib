module openai

import json

pub struct FineTune {
pub:
	id               string
	object           string
	model            string
	created_at       int
	events           []FineTuneEvent
	fine_tuned_model string
	hyperparams      FineTuneHyperParams
	organization_id  string
	result_files     []File
	status           string
	validation_files []File
	training_files   []File
	updated_at       int
}

pub struct FineTuneEvent {
pub:
	object     string
	created_at int
	level      string
	message    string
}

pub struct FineTuneHyperParams {
pub:
	batch_size               int
	learning_rate_multiplier f64
	n_epochs                 int
	prompt_loss_weight       f64
}

pub struct FineTuneList {
pub:
	object string
	data   []FineTune
}

pub struct FineTuneEventList {
pub:
	object string
	data   []FineTuneEvent
}

@[params]
pub struct FineTuneCreateArgs {
pub mut:
	training_file                  string @[required]
	model                          string
	n_epochs                       int = 4
	batch_size                     int
	learning_rate_multiplier       f32
	prompt_loss_weight             f64
	compute_classification_metrics bool
	suffix                         string
}

// creates a new fine-tune based on an already uploaded file
pub fn (mut f OpenAIClient[Config]) create_fine_tune(args FineTuneCreateArgs) !FineTune {
	data := json.encode(args)
	mut conn := f.connection()!
	r := conn.post_json_str(prefix: 'fine-tunes', data: data)!

	return json.decode(FineTune, r)!
}

// returns all fine-tunes in this account
pub fn (mut f OpenAIClient[Config]) list_fine_tunes() !FineTuneList {
	mut conn := f.connection()!
	r := conn.get(prefix: 'fine-tunes')!
	return json.decode(FineTuneList, r)!
}

// get a single fine-tune information
pub fn (mut f OpenAIClient[Config]) get_fine_tune(fine_tune string) !FineTune {
	mut conn := f.connection()!
	r := conn.get(prefix: 'fine-tunes/' + fine_tune)!
	return json.decode(FineTune, r)!
}

// cancel a fine-tune that didn't finish yet
pub fn (mut f OpenAIClient[Config]) cancel_fine_tune(fine_tune string) !FineTune {
	mut conn := f.connection()!
	r := conn.post_json_str(prefix: 'fine-tunes/' + fine_tune + '/cancel')!
	return json.decode(FineTune, r)!
}

// returns all events for a fine tune in this account
pub fn (mut f OpenAIClient[Config]) list_fine_tune_events(fine_tune string) !FineTuneEventList {
	mut conn := f.connection()!
	r := conn.get(prefix: 'fine-tunes/' + fine_tune + '/events')!
	return json.decode(FineTuneEventList, r)!
}
