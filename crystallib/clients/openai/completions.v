module openai

import json

pub struct ChatCompletion {
pub mut:
	id      string
	object  string
	created u32
	choices []Choice
	usage   Usage
}

pub struct Choice {
pub mut:
	index         int
	message       MessageRaw
	finish_reason string
}

pub struct Message {
pub mut:
	role    RoleType
	content string
}

pub struct Usage {
pub mut:
	prompt_tokens     int
	completion_tokens int
	total_tokens      int
}

pub struct Messages {
pub mut:
	messages []Message
}

pub struct MessageRaw {
pub mut:
	role    string
	content string
}

struct ChatMessagesRaw {
mut:
	model    string
	messages []MessageRaw
}

// creates a new chat completion given a list of messages
// each message consists of message content and the role of the author
pub fn (mut f OpenAIClient[Config]) chat_completion(model_type ModelType, msgs Messages) !ChatCompletion {
	model_type0 := modelname_str(model_type)
	mut m := ChatMessagesRaw{
		model: model_type0
	}
	for msg in msgs.messages {
		mr := MessageRaw{
			role:    roletype_str(msg.role)
			content: msg.content
		}
		m.messages << mr
	}
	data := json.encode(m)
	r := f.connection.post_json_str(prefix: 'chat/completions', data: data)!

	res := json.decode(ChatCompletion, r)!
	return res
}
