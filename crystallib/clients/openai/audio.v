module openai

import json
import freeflowuniverse.crystallib.clients.httpconnection
import os
import net.http

pub enum AudioRespType {
	json
	text
	srt
	verbose_json
	vtt
}

const audio_model = 'whisper-1'
const audio_mime_types = {
	'.mp3':  'audio/mpeg'
	'.mp4':  'audio/mp4'
	'.mpeg': 'audio/mpeg'
	'.mpga': 'audio/mp4'
	'.m4a':  'audio/mp4'
	'.wav':  'audio/vnd.wav'
	'.webm': 'application/octet-stream'
}

fn audio_resp_type_str(i AudioRespType) string {
	return match i {
		.json {
			'json'
		}
		.text {
			'text'
		}
		.srt {
			'srt'
		}
		.verbose_json {
			'verbose_json'
		}
		.vtt {
			'vtt'
		}
	}
}

pub struct AudioArgs {
pub mut:
	filepath        string
	prompt          string
	response_format AudioRespType
	temperature     int
	language        string
}

pub struct AudioResponse {
pub mut:
	text string
}

// create transcription from an audio file
// supported audio formats are mp3, mp4, mpeg, mpga, m4a, wav, or webm
pub fn (mut f OpenAIClient[Config]) create_transcription(args AudioArgs) !AudioResponse {
	return f.create_audio_request(args, 'audio/transcriptions')
}

// create translation to english from an audio file
// supported audio formats are mp3, mp4, mpeg, mpga, m4a, wav, or webm
pub fn (mut f OpenAIClient[Config]) create_tranlation(args AudioArgs) !AudioResponse {
	return f.create_audio_request(args, 'audio/translations')
}

fn (mut f OpenAIClient[Config]) create_audio_request(args AudioArgs, endpoint string) !AudioResponse {
	file_content := os.read_file(args.filepath)!
	ext := os.file_ext(args.filepath)
	mut file_mime_type := ''
	if ext in audio_mime_types {
		file_mime_type = audio_mime_types[ext]
	} else {
		return error('file extenion not supported')
	}

	file_data := http.FileData{
		filename:     os.base(args.filepath)
		content_type: file_mime_type
		data:         file_content
	}

	form := http.PostMultipartFormConfig{
		files: {
			'file': [file_data]
		}
		form:  {
			'model':           audio_model
			'prompt':          args.prompt
			'response_format': audio_resp_type_str(args.response_format)
			'temperature':     args.temperature.str()
			'language':        args.language
		}
	}

	req := httpconnection.Request{
		prefix: endpoint
	}
	mut conn := f.connection()!
	r := conn.post_multi_part(req, form)!
	if r.status_code != 200 {
		return error('got error from server: ${r.body}')
	}
	return json.decode(AudioResponse, r.body)!
}
