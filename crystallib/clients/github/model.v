module github

pub struct ProjectDetails {
	id string
}

pub struct ProjectsDetails {
	id    string
	title string
}

pub struct ProjectNodes {
	nodes []ProjectsDetails
}

pub struct OrganizationDetails {
	project_v2  ProjectDetails @[json: 'projectV2']
	projects_v2 ProjectNodes   @[json: 'projectsV2']
}

pub struct DataResp {
	organization OrganizationDetails
}

pub struct ProjectResp {
	data DataResp
}

pub struct QueryRequest {
	query string
}

pub struct ProjectInfoAssigneesNode {
	login string
}

pub struct ProjectInfoAssignees {
	nodes []ProjectInfoAssigneesNode
}

pub struct ProjectInfoContent {
	title     string
	assignees ProjectInfoAssignees
}

pub struct ProjectInfoFieldMeta {
	name string
}

pub struct ProjectInfoFieldNode {
	text  string
	name  string
	date  string
	field ProjectInfoFieldMeta
}

pub struct ProjectInfoField {
	nodes []ProjectInfoFieldNode
}

pub struct ProjectInfoNode {
	id           string
	field_values ProjectInfoField @[json: 'fieldValues']
	content      ProjectInfoContent
}

pub struct ProjectInfoINodes {
	nodes []ProjectInfoNode
}

pub struct ProjectInfoItems {
	items ProjectInfoINodes
}

pub struct ProjectInfoData {
	node ProjectInfoItems
}

pub struct ProjectInfoResp {
	data ProjectInfoData
}
