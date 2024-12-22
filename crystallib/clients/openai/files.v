module openai

import json
import freeflowuniverse.crystallib.clients.httpconnection
import os
import net.http

const jsonl_mime_type = 'text/jsonl'

@[params]
pub struct FileUploadArgs {
pub:
	filepath string
	purpose  string
}

pub struct File {
pub mut:
	id         string
	object     string
	bytes      int
	created_at int
	filename   string
	purpose    string
}

pub struct Files {
pub mut:
	data []File
}

pub struct DeleteResp {
pub mut:
	id      string
	object  string
	deleted bool
}

// upload file to client org, usually used for fine tuning
pub fn (mut f OpenAIClient[Config]) upload_file(args FileUploadArgs) !File {
	file_content := os.read_file(args.filepath)!

	file_data := http.FileData{
		filename:     os.base(args.filepath)
		data:         file_content
		content_type: jsonl_mime_type
	}

	form := http.PostMultipartFormConfig{
		files: {
			'file': [file_data]
		}
		form:  {
			'purpose': args.purpose
		}
	}

	req := httpconnection.Request{
		prefix: 'files'
	}
	mut conn := f.connection()!
	r := conn.post_multi_part(req, form)!
	if r.status_code != 200 {
		return error('got error from server: ${r.body}')
	}
	return json.decode(File, r.body)!
}

// list all files in client org
pub fn (mut f OpenAIClient[Config]) list_files() !Files {
	mut conn := f.connection()!
	r := conn.get(prefix: 'files')!
	return json.decode(Files, r)!
}

// deletes a file
pub fn (mut f OpenAIClient[Config]) delete_file(file_id string) !DeleteResp {
	mut conn := f.connection()!
	r := conn.delete(prefix: 'files/' + file_id)!
	return json.decode(DeleteResp, r)!
}

// returns a single file metadata
pub fn (mut f OpenAIClient[Config]) get_file(file_id string) !File {
	mut conn := f.connection()!
	r := conn.get(prefix: 'files/' + file_id)!
	return json.decode(File, r)!
}

// returns the content of a specific file
pub fn (mut f OpenAIClient[Config]) get_file_content(file_id string) !string {
	mut conn := f.connection()!
	r := conn.get(prefix: 'files/' + file_id + '/content')!
	return r
}
