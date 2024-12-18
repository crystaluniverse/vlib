module organization

import time

@[root_object]
pub struct Epic {
pub mut:
	stories []string
	sprints []string
}

@[root_object]
pub struct Sprint {
pub mut:
	title       string
	description string
	stories     []string
}

@[root_object]
pub struct Story {
	created_at time.Time
pub mut:
	title       string
	description string = 'Our new story'
	tasks       []&Task
}

pub enum StoryStatus {
	todo
	done
}

pub struct Task {
	created_at time.Time
pub:
	story_id string @[root_object: 'Story']
pub mut:
	asignee     string
	title       string
	description string
	priority    Priority
	tags        map[string]string
}

pub enum Priority {
	low
	neutral
	high
}
