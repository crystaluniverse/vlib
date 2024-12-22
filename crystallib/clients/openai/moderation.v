module openai

import json

pub enum ModerationModel {
	text_moderation_latest
	text_moderation_stable
}

fn moderation_model_str(m ModerationModel) string {
	return match m {
		.text_moderation_latest {
			'text-moderation-latest'
		}
		.text_moderation_stable {
			'text-moderation-stable'
		}
	}
}

@[params]
pub struct ModerationRequest {
mut:
	input string
	model string
}

pub struct ModerationResult {
pub mut:
	categories      ModerationResultCategories
	category_scores ModerationResultCategoryScores
	flagged         bool
}

pub struct ModerationResultCategories {
pub mut:
	sexual                 bool
	hate                   bool
	harassment             bool
	selfharm               bool @[json: 'self-harm']
	sexual_minors          bool @[json: 'sexual/minors']
	hate_threatening       bool @[json: 'hate/threatening']
	violence_graphic       bool @[json: 'violence/graphic']
	selfharm_intent        bool @[json: 'self-harm/intent']
	selfharm_instructions  bool @[json: 'self-harm/instructions']
	harassment_threatening bool @[json: 'harassment/threatening']
	violence               bool
}

pub struct ModerationResultCategoryScores {
pub mut:
	sexual                 f32
	hate                   f32
	harassment             f32
	selfharm               f32 @[json: 'self-harm']
	sexual_minors          f32 @[json: 'sexual/minors']
	hate_threatening       f32 @[json: 'hate/threatening']
	violence_graphic       f32 @[json: 'violence/graphic']
	selfharm_intent        f32 @[json: 'self-harm/intent']
	selfharm_instructions  f32 @[json: 'self-harm/instructions']
	harassment_threatening f32 @[json: 'harassment/threatening']
	violence               f32
}

pub struct ModerationResponse {
pub mut:
	id      string
	model   string
	results []ModerationResult
}

pub fn (mut f OpenAIClient[Config]) create_moderation(input string, model ModerationModel) !ModerationResponse {
	req := ModerationRequest{
		input: input
		model: moderation_model_str(model)
	}
	data := json.encode(req)
	mut conn := f.connection()!
	r := conn.post_json_str(prefix: 'moderations', data: data)!
	return json.decode(ModerationResponse, r)!
}
