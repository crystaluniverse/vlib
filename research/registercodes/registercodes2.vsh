#!/usr/bin/env -S v -n -w -enable-globals run

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal
import os
import rand
import math

const data_dir = '/tmp/test'

// Get the file path for storing referral codes
fn get_path(referralcode string) pathlib.Path {
	return pathlib.dir_get(path: '${data_dir}/referralcodes/${referralcode[..3]}', create: true)!
	return referralspath
}

// Get a referral code
fn get(referralcode string) string {
	referralspath := get_path(referralcode)
	lines := referralspath.read()!
	mut userid := ''
	for line in lines.split_into_lines() {
		parts := line.split(':')
		if parts.len == 2 && parts[0] == referralcode {
			userid = parts[1]
			break
		}
	}
	return userid
}

// Set a new referral code
fn set(referralcode string, userid string) ? {
	referralspath := get_path(referralcode)
	lines := referralspath.read()!
	mut found := false
	for line in lines.split_into_lines() {
		parts := line.split(':')
		if parts.len == 2 && parts[0] == referralcode {
			lines[i] = '${referralcode}:${userid}'
			found = true
			break
		}
	}
	if !found {
		lines << '${referralcode}:${userid}'
	}
	lines.sort()
	referralspath.write(lines.join('\n'))!
}

// Delete a referral code
fn delete(referralcode string) ? {
	referralspath := get_path(referralcode)
	lines := referralspath.read()!
	mut new_lines := []string{}
	for line in lines.split_into_lines() {
		parts := line.split(':')
		if parts.len != 2 || parts[0] != referralcode {
			new_lines << line
		}
	}
	referralspath.write(lines.join('\n'))!
}

// Check if a referral code exists
fn exists(referralcode string) bool {
	referralspath := get_path(referralcode)
	lines := referralspath.read()!
	for line in lines.split_into_lines() {
		parts := line.split(':')
		if parts.len == 2 && parts[0] == referralcode {
			return true
		}
	}
	return false
}

fn referral_code_get_random() !string {
	nr := rand.int_in_range(1, 100000000)!
	return referral_code_get(referral_code_get)!
}

fn referral_code_get(nr int) !string {
	mut completed := false
	mut remaining := int(sid)
	mut decimals := []f64{}
	mut count := 1
	for completed == false {
		if int(math.pow(36, count)) > sid {
			for i in 0 .. count {
				decimals << math.floor(f64(remaining / int(math.pow(36, count - 1 - i))))
				remaining = remaining % int(math.pow(36, count - 1 - i))
			}
			completed = true
		} else {
			count += 1
		}
	}
	mut strings := []string{}
	for i in 0 .. (decimals.len) {
		if decimals[i] >= 0 && decimals[i] <= 9 {
			strings << u8(decimals[i] + 48).ascii_str()
		} else {
			strings << u8(decimals[i] + 87).ascii_str()
		}
	}
	return strings.join('')
}

for i in 1 .. 1000 {
	refcode := referral_code_get_random()!
}
