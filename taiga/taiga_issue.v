module taiga

import json
import x.json2 {raw_decode}
import time {Time}
// struct IssueList {
// pub mut:
// 	issues []Issue
// }

struct Issue {
pub mut:
	description            string
	id                     int
	is_private             bool
	tags                   []string
	project                int
	project_extra_info     ProjectInfo
	status                 int
	status_extra_info      StatusInfo
	assigned_to            int
	assigned_to_extra_info UserInfo
	owner                  int
	owner_extra_info       UserInfo
	severity               int
	priority               int
	issue_type             int  [json: 'type']
	created_date           Time [skip]
	modified_date          Time [skip]
	finished_date          Time [skip]
	subject                string
	is_closed              bool
	is_blocked             bool
	blocked_note           string
	ref                    int
	comments               []Comment
}

struct NewIssue {
pub mut:
	subject string
	project int
}

//get comments in list from issue
pub fn (mut i Issue) get_issue_comments() ?[]Comment {
	i.comments = comments_get("issue", i.id) ?
	return i.comments
}

pub fn issues() ?[]Issue {
	mut conn := connection_get()
	data := conn.get_json_str('issues', '', true) ?
	data_as_arr := (raw_decode(data) or {}).arr()
	mut issues := []Issue{}
	for i in data_as_arr {
		mut issue := issue_decode(i.str()) ?
		issue.get_issue_comments() ?
		issue_remember(issue)
	}
	return issues
}

// create issue based on our standards
pub fn (mut h TaigaConnection) issue_create(subject string, project_id int) ?Issue {
	// TODO
	mut conn :=  connection_get()
	conn.cache_drop()? //to make sure all is consistent, can do this more refined, now we drop all
	issue := NewIssue{
		subject: subject
		project: project_id
	}
	postdata := json.encode_pretty(issue)
	response := h.post_json_str('issues', postdata, true, true) ?
	mut result := json.decode(Issue, response) ?
	return result
}

pub fn (mut h TaigaConnection) issue_get(id int) ?Issue {
	// TODO: Check Cache first (Mohammed Essam), cache should be on higher level
	mut conn :=  connection_get()
	response := conn.get_json_str('issues/$id', "", true) ?
	mut result := json.decode(Issue, response) ?
	return result
}

fn issue_decode(data string) ? Issue{
	mut issue := json.decode(Issue, data) ?
	data_as_map := (raw_decode(data) or {}).as_map()
	issue.created_date = parse_time(data_as_map["created_date"].str())
	issue.modified_date = parse_time(data_as_map["modified_date"].str())
	issue.finished_date = parse_time(data_as_map["modified_date"].str())
	return issue
}