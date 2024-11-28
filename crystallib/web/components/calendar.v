module components

import net.urllib
import time

struct CalendarView {
pub:
	title string
    events []CalendarEvent
    current_year int = 2024
    current_month int = 8 // September (0-indexed)

}

struct CalendarEvent {
pub:
    subject string
    date    string
    hour    string
    link    string
}

fn (mut self CalendarView) validate() ! {
    if self.current_year < 2000 || self.current_year > 2060 {
        return error('Invalid year value (2000-2060)')
    }
    if self.current_month < 0 || self.current_month > 11 {
        return error('Invalid month value (0-11)')
    }
	for mut event in self.events {
		event.validate()!

	}
}

fn (mut event CalendarEvent) validate() ! {
    // Check date format (dd/mm/yy)
    date_parts := event.date.split('/')
    if date_parts.len != 3 {
        return error('Invalid date format. Expected dd/mm/yy')
    }
    day := date_parts[0].int()
    month := date_parts[1].int()
    year := date_parts[2].int()
    
    if day < 1 || day > 31 || month < 1 || month > 12 || year < 0 || year > 99 {
        return error('Invalid date values')
    }
    
    // Check hour format (HH:MM)
    hour_parts := event.hour.split(':')
    if hour_parts.len != 2 {
        return error('Invalid hour format. Expected HH:MM')
    }
    hours := hour_parts[0].int()
    minutes := hour_parts[1].int()
    
    if hours < 0 || hours > 23 || minutes < 0 || minutes > 59 {
        return error('Invalid hour values')
    }
    
    // Check link format
    url := urllib.parse(event.link) or {
        return error('Invalid URL format')
    }
    if url.scheme == '' || url.host == '' {
        return error('Invalid URL: missing scheme or host')
    }
    
}

fn calendar_example() CalendarView {
    calendar_data := [
        CalendarEvent{
            subject: 'Team Meeting'
            date: '15/09/24'
            hour: '10:00'
            link: 'https://example.com/meeting1'
        },
        CalendarEvent{
            subject: 'Project Deadline'
            date: '20/09/24'
            hour: '17:00'
            link: 'https://example.com/project1'
        },
        CalendarEvent{
            subject: 'Lunch with Client'
            date: '25/09/24'
            hour: '12:30'
            link: 'https://example.com/lunch1'
        },
        CalendarEvent{
            subject: 'Conference Call'
            date: '28/09/24'
            hour: '14:00'
            link: 'https://example.com/call1'
        },
        CalendarEvent{
            subject: 'Training Session'
            date: '28/09/24'
            hour: '09:00'
            link: 'https://example.com/training1'
        },
    ]

	mut calendar := CalendarView{
		title: 'Upcoming Events'
		events: calendar_data
	}

	return calendar
}


fn (mut self CalendarView) generate_calendar() string {
    first_day := time.new(time.Time{
        year: self.current_year
        month: self.current_month
        day: 1
    })
    last_day := time.new(time.Time{
        year: self.current_year
        month: self.current_month + 1
        day: 0
    })
    days_in_month := last_day.day
    starting_day := int(first_day.day_of_week())

    mut calendar_html := '<div class="calendar">'
    day_names := ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

    // Add day names
    for day in day_names {
        calendar_html += '<div class="day-header">$day</div>'
    }

    // Add empty cells for days before the first of the month
    for _ in 0 .. starting_day {
        calendar_html += '<div class="day"></div>'
    }

    //TODO: fix, is a port from the javascript but not good enough yet, maybe keeping the fill in of the html as template would be better

    // // Add days and events
    // for day in 1 .. days_in_month + 1 {
    //     current_date := '${day:02d}/${self.current_month:02d}/${self.current_year:04d}'
    //     events := self.calendar_data.filter(it.date == current_date)

    //     calendar_html += '<div class="day">
    //                 <div class="day-header">$day</div>'

    //     for event in events[..arrays.min(events.len, 4)] {
    //         calendar_html += '<div class="event" title="$event.subject">
    //                     <a href="$event.link" target="_blank">$event.hour - $event.subject</a>
    //                 </div>'
    //     }

    //     if events.len > 4 {
    //         calendar_html += '<div class="more-events">+${events.len - 4} more</div>'
    //     }

    //     calendar_html += '</div>'
    // }

    calendar_html += '</div>'
    return calendar_html
}