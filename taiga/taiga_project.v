module taiga

import x.json2 {raw_decode}
import json
import os
import time {Time}

struct Project {
pub mut:
	created_date  Time  [skip]
	modified_date Time  [skip]
	name          string
	description   string
	id            int
	is_private    bool
	members       []int
	tags          []string
	slug          string
	owner         UserInfo
	projtype      Projectype [skip]
	file_name     string     [skip]
}


pub enum Projectype {
	funnel
	project
	team
}

pub enum TaigaElementTypes{
	story
	issue
	task
	epic
}

pub struct ProjectElements {
pub mut:
	stories []Story
	issues  []Issue
	tasks   []Task
	epics   []Epic
}


pub fn (mut p Project) delete() ?bool {
	mut conn := connection_get()
	return conn.delete('projects', p.id)
}


pub fn (mut p Project) stories() ?[]Story {
	mut conn := connection_get()
	data := conn.get_json_str('userstories?project=$p.id', '', false) ?
	return json.decode([]Story, data) or {}
}

// //get comments in lis from project
// pub fn (mut p Project) issues() ?[]Issue {
// 	mut conn := connection_get()
// 	// no cache for now, fix later
// 	data := conn.get_json_str('userstories?project=$p.id', '', false) ?
// 	return json.decode([]Story, data) or {}
// 	panic("implement")
// }


pub fn (mut p Project) copy (element_type TaigaElementTypes, element_id int, to_project_id int) ?TaigaElement {
	/*
	Copy story, issue, task and epic from project to other one.
	Inputs:
		element_type: enum --> story, issue, task and epic
		element_id: id of the element we want to copy
		to_project_id: id of the destination project
	Output
		new_element: return the new element casted as TaigaElement Type
	*/
	mut conn := connection_get()
	mut new_element := TaigaElement(Issue{}) // Initialize with any empty element type
	match element_type{
		.story {
			//Get element
			element := story_get(element_id) ?
			// Create new element in the distination project
			new_element = story_create(element.subject, to_project_id) ?
		}
		.issue {
			element := issue_get(element_id) ?
			new_element = issue_create(element.subject, to_project_id) ?
		}
		.task {
			element := task_get(element_id) ?
			new_element = task_create(element.subject, to_project_id) ?
		}
		.epic {
			element := epic_get(element_id) ?
			new_element = epic_create(element.subject, to_project_id) ?
		}
	}
	//TODO: guess this is not finished??? we need to copy the content
	panic("not implemented")
	return new_element
}

fn project_decode(data string) ? Project{
	mut project := json.decode(Project, data) ?
	data_as_map := (raw_decode(data) or {}).as_map()
	project.created_date = parse_time(data_as_map["created_date"].str())
	project.modified_date = parse_time(data_as_map["modified_date"].str())
	project.file_name = project.slug + ".md"
	return project
}

fn (project Project) as_md (url string) string {
	stories := stories_per_project(project.id) // For template rendering
	issues := issues_per_project(project.id) // For template rendering
	tasks := tasks_per_project(project.id) // For template rendering
	epics := epics_per_project(project.id) // For template rendering
	// export template per project
	mut proj_md := $tmpl('./templates/project.md')
	proj_md = fix_empty_lines(proj_md)
	return proj_md
}