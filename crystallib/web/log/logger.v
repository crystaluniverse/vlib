module log

import db.sqlite

pub fn (logger Logger) new_log(log Log) ! {
	db := sqlite.connect(logger.db_path)!

	sql db {
		insert log into Log
	}!
}

pub struct LogFilter {
	Log
	matches_all bool
	limit int
}

pub fn (logger Logger) filter_logs(filter LogFilter) ![]Log {
	db := sqlite.connect(logger.db_path)!
	mut select_stmt := 'select * from Log'

	mut matchers := []string{}
	if filter.event != '' {
		matchers << "event == '${filter.event}'"
	}
    
	if filter.subject != '' {
		matchers << "subject == '${filter.subject}'"
	}

	if filter.object != '' {
		matchers << "object == '${filter.object}'"
	}

	if matchers.len > 0 {
		matchers_str := if filter.matches_all {
			matchers.join(' AND ')
		} else {
			matchers.join(' OR ')
		}
		select_stmt += ' where ${matchers_str}'
	}

	responses := db.exec(select_stmt)!
	
	mut logs := []Log{}
	for response in responses {
		logs << sql db {
			select from Log where id == response.vals[0].int()
		}!
	}

	return logs
}