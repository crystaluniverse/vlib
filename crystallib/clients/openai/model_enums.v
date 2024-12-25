module openai

pub enum ModelType {
	gpt_4_1106_preview
	gpt_4_vision_preview
	gpt_4
	gpt_4_32k
	gpt_3_5_turbo_1106
	gpt_3_5_turbo
	gpt_3_5_turbo_16k
	whisper_1
}

fn modelname_str(e ModelType) string {
	return match e {
		.gpt_4_1106_preview {
			'gpt-4-1106-preview'
		}
		.gpt_4_vision_preview {
			'gpt-4-vision-preview'
		}
		.gpt_4 {
			'gpt-4'
		}
		.gpt_4_32k {
			'gpt-4-32k'
		}
		.gpt_3_5_turbo_1106 {
			'gpt-3.5-turbo-1106'
		}
		.gpt_3_5_turbo {
			'gpt-3.5-turbo'
		}
		.gpt_3_5_turbo_16k {
			'gpt-3.5-turbo-16k'
		}
		.whisper_1 {
			'whisper-1'
		}
	}
}

pub enum RoleType {
	system
	user
	assistant
	function
}

fn roletype_str(x RoleType) string {
	return match x {
		.system {
			'system'
		}
		.user {
			'user'
		}
		.assistant {
			'assistant'
		}
		.function {
			'function'
		}
	}
}
