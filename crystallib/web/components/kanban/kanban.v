module kanban

pub struct Project {
pub:
	id         string
	title      string
	board      Board
	edit_url   string
	close_url  string
	delete_url string
}

pub struct Board {
pub:
	title    string
	move_url string
	columns  []Column
}

pub struct Column {
pub:
	id             int
	title string
	name           string
	color          string
	issues         []Issue
	is_default     bool
	sorting        string
	url            string
	issue_count    int
	delete_url     string
	delete_text    string
	delete_modal   string
	default_url    string
	default_text   string
	edit_text      string
	edit_modal     string
	default_modal  string
}

pub struct Issue {
pub:
	id          int
	title       string
	description string
	assignees   []Assignee
	status      string
	meta        string
	url         string
}

pub struct Assignee {
pub:
	name       string
	url        string
	avatar_url string
}

pub fn (project Project) html() string {
	board := project.board
	style := $tmpl('templates/board.css')
	return $tmpl('templates/board.html')
}

pub fn mock() Project {
	return Project{
		id: '1'
		title: 'Project Management Board'
		board: Board{
			title: 'Project Management Board'
			move_url: '/board/move'
			columns: [
				Column{
					id: 1
					title: 'Tasks to Start'
					name: 'To Do'
					color: '#FFDDC1'
					issues: [
						Issue{
							id: 1
							title: 'Design login page'
							description: 'Create a responsive login page based on the design specifications.'
							assignees: [
								Assignee{name: 'Alice', avatar_url: 'https://example.com/avatar/alice.png'},
							]
							status: 'To Do'
							meta: 'Priority: High'
							url: '/issue/1'
						},
						Issue{
							id: 2
							title: 'Setup database'
							description: 'Initialize the database with the required schema and seed data.'
							assignees: [
								Assignee{name: 'Bob', avatar_url: 'https://example.com/avatar/bob.png'},
							]
							status: 'To Do'
							meta: 'Priority: Medium'
							url: '/issue/2'
						},
					]
					is_default: true
					sorting: '1'
					url: '/column/1'
					issue_count: 2
					delete_url: '/column/1/delete'
					delete_text: 'Delete Column'
					delete_modal: 'Are you sure you want to delete this column?'
					default_url: '/column/1/default'
					default_text: 'Set as Default'
					edit_text: 'Edit Column'
					edit_modal: '/column/1/edit'
					default_modal: '/column/1/default_modal'
				},
				Column{
					id: 2
					title: 'In Progress Work'
					name: 'In Progress'
					color: '#C1E1C1'
					issues: [
						Issue{
							id: 3
							title: 'Implement user authentication'
							description: 'Develop backend authentication with JWT.'
							assignees: [
								Assignee{name: 'Charlie', avatar_url: 'https://example.com/avatar/charlie.png'},
								Assignee{name: 'Dana', avatar_url: 'https://example.com/avatar/dana.png'},
							]
							status: 'In Progress'
							meta: 'Priority: High'
							url: '/issue/3'
						},
						Issue{
							id: 4
							title: 'Create frontend API integration'
							description: 'Integrate API endpoints with the frontend application.'
							assignees: [
								Assignee{name: 'Eve', avatar_url: 'https://example.com/avatar/eve.png'},
							]
							status: 'In Progress'
							meta: 'Priority: Low'
							url: '/issue/4'
						},
					]
					is_default: false
					sorting: '2'
					url: '/column/2'
					issue_count: 2
					delete_url: '/column/2/delete'
					delete_text: 'Delete Column'
					delete_modal: 'Are you sure you want to delete this column?'
					default_url: '/column/2/default'
					default_text: 'Set as Default'
					edit_text: 'Edit Column'
					edit_modal: '/column/2/edit'
					default_modal: '/column/2/default_modal'
				},
				Column{
					id: 3
					title: 'Completed Tasks'
					name: 'Done'
					color: '#D1C4E9'
					issues: [
						Issue{
							id: 5
							title: 'Setup CI/CD pipeline'
							description: 'Create automated deployment workflows using GitHub Actions.'
							assignees: [
								Assignee{name: 'Frank', avatar_url: 'https://example.com/avatar/frank.png'},
							]
							status: 'Done'
							meta: 'Priority: Medium'
							url: '/issue/5'
						},
						Issue{
							id: 6
							title: 'Finalize project documentation'
							description: 'Ensure that the project documentation is complete and up-to-date.'
							assignees: [
								Assignee{name: 'Grace', avatar_url: 'https://example.com/avatar/grace.png'},
							]
							status: 'Done'
							meta: 'Priority: Low'
							url: '/issue/6'
						},
					]
					is_default: false
					sorting: '3'
					url: '/column/3'
					issue_count: 2
					delete_url: '/column/3/delete'
					delete_text: 'Delete Column'
					delete_modal: 'Are you sure you want to delete this column?'
					default_url: '/column/3/default'
					default_text: 'Set as Default'
					edit_text: 'Edit Column'
					edit_modal: '/column/3/edit'
					default_modal: '/column/3/default_modal'
				},
			]
		}
		edit_url: '/project/edit'
		close_url: '/project/close'
		delete_url: '/project/delete'
	}
}