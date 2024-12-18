module projectmanager

import os
import source { Story }

const db_dir = '${os.home_dir()}/hero/db'
const actor_name = 'ProjectManager_test_actor'

//
pub fn testsuite_begin() {
	if os.exists('${db_dir}/${actor_name}') {
		os.rmdir_all('${db_dir}/${actor_name}')!
	}
	if os.exists('${db_dir}/${actor_name}.sqlite') {
		os.rm('${db_dir}/${actor_name}.sqlite')!
	}
}

//
pub fn testsuite_end() {
	if os.exists('${db_dir}/${actor_name}') {
		os.rmdir_all('${db_dir}/${actor_name}')!
	}
	if os.exists('${db_dir}/${actor_name}.sqlite') {
		os.rm('${db_dir}/${actor_name}.sqlite')!
	}
}

// creates the Story with the given object id
pub fn test_create_story() ! {
	mut actor := get(name: actor_name)!
	mut story_id := actor.create_story(Story{ name: 'mock_string_SXz' })!
	assert story_id == 1

	story_id = actor.create_story(Story{ name: 'mock_string_SXz' })!
	assert story_id == 2
}

// creates the Story with the given object id
pub fn test_read_story() ! {
	mut actor := get(name: actor_name)!
	mut story := Story{
		name: 'mock_string_fqW'
	}
	story.id = '${actor.create_story(story)!}'
	assert story == actor.read_story(story.id)!
}

// creates the Story with the given object id
pub fn test_filter_story() ! {
	mut actor := get(name: actor_name)!

	story_id0 := actor.create_story(Story{ tag: 'mock_string_DWn', name: 'mock_string_EZN' })!
	story_list0 := actor.filter_story(
		filter: StoryFilter{
			tag: 'mock_string_DWn'
		}
	)!
	assert story_list0.len == 1
	assert story_list0[0].tag == 'mock_string_DWn'
}
