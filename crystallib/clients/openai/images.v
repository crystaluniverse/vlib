module openai

import json
import net.http
import os
import freeflowuniverse.crystallib.clients.httpconnection

const image_mine_type = 'image/png'

pub enum ImageSize {
	size_256_256
	size_512_512
	size_1024_1024
}

fn image_size_str(i ImageSize) string {
	return match i {
		.size_256_256 {
			'256x256'
		}
		.size_512_512 {
			'512x512'
		}
		.size_1024_1024 {
			'1024x1024'
		}
	}
}

pub enum ImageRespType {
	url
	b64_json
}

fn image_resp_type_str(i ImageRespType) string {
	return match i {
		.url {
			'url'
		}
		.b64_json {
			'b64_json'
		}
	}
}

pub struct ImageCreateArgs {
pub mut:
	prompt     string
	num_images int
	size       ImageSize
	format     ImageRespType
	user       string
}

pub struct ImageEditArgs {
pub mut:
	image_path string
	mask_path  string
	prompt     string
	num_images int
	size       ImageSize
	format     ImageRespType
	user       string
}

pub struct ImageVariationArgs {
pub mut:
	image_path string
	num_images int
	size       ImageSize
	format     ImageRespType
	user       string
}

pub struct ImageRequest {
pub mut:
	prompt          string
	n               int
	size            string
	response_format string
	user            string
}

pub struct ImageResponse {
pub mut:
	url      string
	b64_json string
}

pub struct Images {
pub mut:
	created int
	data    []ImageResponse
}

// Create new images generation given a prompt
// the amount of images returned is specified by `num_images`
pub fn (mut f OpenAIClient[Config]) create_image(args ImageCreateArgs) !Images {
	image_size := image_size_str(args.size)
	response_format := image_resp_type_str(args.format)
	request := ImageRequest{
		prompt:          args.prompt
		n:               args.num_images
		size:            image_size
		response_format: response_format
		user:            args.user
	}
	data := json.encode(request)
	r := f.connection.post_json_str(prefix: 'images/generations', data: data)!
	return json.decode(Images, r)!
}

// edit images generation given a prompt and an existing image
// image needs to be in PNG format and transparent or else a mask of the same size needs
// to be specified to indicate where the image should be in the generated image
// the amount of images returned is specified by `num_images`
pub fn (mut f OpenAIClient[Config]) create_edit_image(args ImageEditArgs) !Images {
	image_content := os.read_file(args.image_path)!
	image_file := http.FileData{
		filename:     os.base(args.image_path)
		content_type: image_mine_type
		data:         image_content
	}
	mut mask_file := []http.FileData{}
	if args.mask_path != '' {
		mask_content := os.read_file(args.mask_path)!
		mask_file << http.FileData{
			filename:     os.base(args.mask_path)
			content_type: image_mine_type
			data:         mask_content
		}
	}

	form := http.PostMultipartFormConfig{
		files: {
			'image': [image_file]
			'mask':  mask_file
		}
		form:  {
			'prompt':          args.prompt
			'n':               args.num_images.str()
			'response_format': image_resp_type_str(args.format)
			'size':            image_size_str(args.size)
			'user':            args.user
		}
	}

	req := httpconnection.Request{
		prefix: 'images/edits'
	}
	r := f.connection.post_multi_part(req, form)!
	if r.status_code != 200 {
		return error('got error from server: ${r.body}')
	}
	return json.decode(Images, r.body)!
}

// create variations of the given image
// image needs to be in PNG format
// the amount of images returned is specified by `num_images`
pub fn (mut f OpenAIClient[Config]) create_variation_image(args ImageVariationArgs) !Images {
	image_content := os.read_file(args.image_path)!
	image_file := http.FileData{
		filename:     os.base(args.image_path)
		content_type: image_mine_type
		data:         image_content
	}

	form := http.PostMultipartFormConfig{
		files: {
			'image': [image_file]
		}
		form:  {
			'n':               args.num_images.str()
			'response_format': image_resp_type_str(args.format)
			'size':            image_size_str(args.size)
			'user':            args.user
		}
	}

	req := httpconnection.Request{
		prefix: 'images/variations'
	}
	r := f.connection.post_multi_part(req, form)!
	if r.status_code != 200 {
		return error('got error from server: ${r.body}')
	}
	return json.decode(Images, r.body)!
}
