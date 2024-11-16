module components

pub struct Swimlane {
    pub:
        name  string
        color ColorEnum
}

pub struct Event {
pub:
    swimlane string
    subject  string
    deadline string
    link     string
    color    ColorEnum
    assigned string
    priority PriorityEnum
    labels   string //comma separated
}

pub enum PriorityEnum {
    critical
    urgent
    normal
    low
    no
}

fn priority_colorenum(prio PriorityEnum) ColorEnum {
    return match prio {
        .critical { .red }
        .urgent { .red }
        .normal { .green }
        .low { .yellow }
        .no { .white }
    }
}


pub struct KanbanViewData {
pub:
    swimlanes []Swimlane
    events    []Event
}

pub fn kanban_example() KanbanViewData  {
    kanban_data := KanbanViewData{
        swimlanes: [
            Swimlane{
                name: 'To Do'
                color: .gray
            },
            Swimlane{
                name: 'In Progress'
                color: .gray
            },
            Swimlane{
                name: 'Review'
                color: .gray
            },
            Swimlane{
                name: 'Done'
                color: .gray
            },
        ]
        events: [
            Event{
                swimlane: 'To Do'
                subject: 'Implement login feature'
                deadline: '30/09/24'
                link: 'https://example.com/task/1'
                color: .blue
                assigned: 'John Doe, Jane Smith'
                priority: .urgent
                labels: 'feature, security'
            },
            Event{
                swimlane: 'To Do'
                subject: 'Something Else'
                deadline: '30/10/24'
                link: 'https://example.com/task/1'
                color: .yellow
                assigned: 'John Doe, Jane Smith'
                priority: .no
                labels: 'feature, security'
            },
            Event{
                swimlane: 'In Progress'
                subject: 'Fix homepage layout'
                deadline: '15/09/24'
                link: 'https://example.com/task/2'
                color: .red
                assigned: 'Alice Johnson'
                priority: .normal
                labels: 'bug, ui'
            },
            Event{
                swimlane: 'Review'
                subject: 'Add unit tests for API'
                deadline: '20/09/24'
                link: 'https://example.com/task/3'
                color: .yellow
                assigned: 'Bob Wilson'
                priority: .low
                labels: 'testing, api'
            },
            Event{
                swimlane: 'Done'
                subject: 'Update documentation'
                deadline: '10/09/24'
                link: 'https://example.com/task/4'
                color: .green
                assigned: 'Emma Brown'
                priority: .urgent
                labels: 'documentation'
            },
        ]
    }
    return kanban_data
}

pub fn (data KanbanViewData) html() string {
	return $tmpl('templates/kanban.html')
}
