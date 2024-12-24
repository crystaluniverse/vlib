module openai

import json

pub enum EmbeddingModel {
	text_embedding_ada
}

fn embedding_model_str(e EmbeddingModel) string {
	return match e {
		.text_embedding_ada {
			'text-embedding-ada-002'
		}
	}
}

@[params]
pub struct EmbeddingCreateArgs {
	input []string       @[required]
	model EmbeddingModel @[required]
	user  string
}

pub struct Embedding {
pub mut:
	object    string
	embedding []f32
	index     int
}

pub struct EmbeddingResponse {
pub mut:
	object string
	data   []Embedding
	model  string
	usage  Usage
}

pub fn (mut f OpenAIClient[Config]) create_embeddings(args EmbeddingCreateArgs) !EmbeddingResponse {
	mut conn := f.connection()!
	return conn.post_json_generic[EmbeddingResponse](
		method:     .post
		prefix:     'embeddings'
		params:     {
			'input': args.input.str()
			'model': embedding_model_str(args.model)
			'user':  args.user
		}
		dataformat: .json
	)!
}
