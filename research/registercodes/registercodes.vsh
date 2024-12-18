#!/usr/bin/env -S v -n -w -enable-globals run

import freeflowuniverse.crystallib.core.texttools
import os
import regex
import math
import rand

const data_dir = '/tmp/dir'

fn get_path(referralcode string) string {
	mydirpath := '${data_dir}/referralcodes'
	os.mkdir_all(mydirpath) or {}
	filepath := os.join_path(mydirpath, '${referralcode[..3]}.txt')
	if !os.exists(filepath) {
		os.create(filepath) or {}
	}
	return filepath
}

fn get(referralcode string) string {
	filepath := get_path(referralcode)
	contents := os.read_file(filepath) or { return '' }
	for line in contents.split_into_lines() {
		re := regex.regex_opt(r'^(?P<referralcode>[a-z0-9]{6}):(?P<userid>\d+)$') or { panic(err) }
		mut match_ := re.find_all_str(line)
		if match_.len > 0 && match_[0]['referralcode'] == referralcode {
			return match_[0]['userid']
		}
	}
	return ''
}

fn set(referralcode string, userid string) {
	filepath := get_path(referralcode)
	mut lines := []string{}
	contents := os.read_file(filepath) or { '' }
	for line in contents.split_into_lines() {
		re := regex.regex_opt(r'^(?P<referralcode>[a-z0-9]{6}):(?P<userid>\d+)$') or { panic(err) }
		mut mymatch := re.find_all_str(line)
		if mymatch.len > 0 {
			lines << '${mymatch[0]['referralcode']}:${mymatch[0]['userid']}'
		}
	}
	lines << '${referralcode}:${userid}'
	lines.sort()
	os.write_file(filepath, lines.join('\n')) or {}
}

fn delete(referralcode string) {
	filepath := get_path(referralcode)
	mut lines := []string{}
	contents := os.read_file(filepath) or { '' }
	for line in contents.split_into_lines() {
		re := regex.regex_opt(r'^(?P<referralcode>[a-z0-9]{6}):(?P<userid>\d+)$') or { panic(err) }
		mut mymatch := re.find_all_str(line)
		if mymatch.len == 0 || mymatch[0]['referralcode'] != referralcode {
			lines << line
		}
	}
	os.write_file(filepath, lines.join('\n')) or {}
}

fn exists(referralcode string) bool {
	filepath := get_path(referralcode)
	contents := os.read_file(filepath) or { return false }
	for line in contents.split_into_lines() {
		re := regex.regex_opt(r'^(?P<referralcode>[a-z0-9]{6}):(?P<userid>\d+)$') or { panic(err) }
		mut mymatch := re.find_all_str(line)
		if mymatch.len > 0 && mymatch[0]['referralcode'] == referralcode {
			return true
		}
	}
	return false
}
