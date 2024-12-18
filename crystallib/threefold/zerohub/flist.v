module zerohub

import net.http
import json
import x.json2
import os

pub struct Repository {
pub:
	name     string
	official bool
}

pub struct FlistInfo {
pub:
	name     string
	size     string
	updated  i64
	type_    string
	linktime i64
	target   string
}

pub struct FlistContents {
pub:
	regular   i32
	failure   i32
	directory i32
	symlink   string
	fullsize  i64
	content   []File
}

pub struct File {
pub:
	size i64
	path string
}

pub fn (mut cl ZeroHubClient) get_flists() ![]string {
	resp := http.get('https://${cl.url}/api/flist')!
	return json.decode([]string, resp.body)!
}

pub fn (mut cl ZeroHubClient) get_repos() ![]Repository {
	resp := http.get('https://${cl.url}/api/repositories')!
	return json.decode([]Repository, resp.body)!
}

pub fn (mut cl ZeroHubClient) get_files() !map[string][]FlistInfo {
	resp := http.get('https://${cl.url}/api/fileslist')!
	return json.decode(map[string][]FlistInfo, resp.body)
}

pub fn (mut cl ZeroHubClient) get_repo_flists(repo_name string) ![]FlistInfo {
	resp := http.get('https://${cl.url}/api/flist/${repo_name}')!
	return json.decode([]FlistInfo, resp.body)
}

pub fn (mut cl ZeroHubClient) get_flist_dump(repo_name string, flist_name string) !FlistContents {
	resp := http.get('https://${cl.url}/api/flist/${repo_name}/${flist_name}')!
	data := json.decode(FlistContents, resp.body)!
	return data
}

pub fn (mut cl ZeroHubClient) get_me() !json2.Any {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    'https://${cl.url}/api/flist/me'
	}

	resp := req.do()!
	return json2.raw_decode(resp.body)!
}

pub fn (mut cl ZeroHubClient) get_my_flist(flist string) !FlistContents {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    'https://${cl.url}/api/flist/me/${flist}'
	}

	resp := req.do()!
	data := json.decode(FlistContents, resp.body)!
	return data
}

pub fn (mut cl ZeroHubClient) remove_my_flist(flist string) !json2.Any {
	req := http.Request{
		method: http.Method.delete
		header: cl.header
		url:    'https://${cl.url}/api/flist/me/${flist}'
	}

	resp := req.do()!
	return json2.raw_decode(resp.body)!
}

pub fn (mut cl ZeroHubClient) symlink(source string, linkname string) !string {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    'https://${cl.url}/api/flist/me/${source}/link/${linkname}'
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl ZeroHubClient) cross_symlink(repo string, source string, linkname string) !string {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    'https://${cl.url}/api/flist/me/${linkname}/crosslink/${repo}/${source}'
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl ZeroHubClient) rename(source string, dest string) !string {
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    'https://${cl.url}/api/flist/me/${source}/rename/${dest}'
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl ZeroHubClient) promote(source_repo string, source_name string, localname string) !string {
	// Copy cross-repository sourcerepo/sourcefile to your [local-repository]/localname
	req := http.Request{
		method: http.Method.get
		header: cl.header
		url:    'https://${cl.url}/api/flist/me/promote/${source_repo}/${source_name}/${localname}'
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl ZeroHubClient) convert(image string) !string {
	form := http.PostMultipartFormConfig{
		form:   {
			'image': image
		}
		header: cl.header
	}

	resp := http.post_multipart_form('https://${cl.url}/api/flist/me/docker', form)!
	return resp.body
}

pub fn (mut cl ZeroHubClient) merge_flists(flists []string, target string) !string {
	req := http.Request{
		method: http.Method.post
		header: cl.header
		url:    'https://${cl.url}/api/flist/me/merge/${target}'
		data:   json.encode(flists)
	}
	resp := req.do()!
	return resp.body
}

pub fn (mut cl ZeroHubClient) upload_flist(path string) !os.Result {
	cmd := "curl -X Post -H 'Authorization: Bearer ${cl.secret}' -F 'file=@${path}'	https://${cl.url}/api/flist/me/upload-flist"

	res := os.execute(cmd)
	return res
}

pub fn (mut cl ZeroHubClient) upload_archive(path string) !os.Result {
	cmd := "curl -X Post -H 'Authorization: Bearer ${cl.secret}' -F 'file=@${path}'	https://${cl.url}/api/flist/me/upload"

	res := os.execute(cmd)
	return res
}
