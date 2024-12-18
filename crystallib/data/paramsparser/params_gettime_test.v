module paramsparser

import freeflowuniverse.crystallib.data.ourtime
import time

const testparams = Params{
	params: [
		Param{
			key:   'when'
			value: '2022-12-5 20:14:35'
		},
		Param{
			key:   'date'
			value: '2022-12-5'
		},
		Param{
			key:   'interval'
			value: '2022-12-5'
		},
		Param{
			key:   'timestamp_12h_format_am'
			value: '10AM'
		},
		Param{
			key:   'timestamp_12h_format_pm'
			value: '8PM'
		},
		Param{
			key:   'timestamp_12h_format_am_minutes'
			value: '10:13AM'
		},
		Param{
			key:   'timestamp_12h_format_pm_minutes'
			value: '8:07PM'
		},
		Param{
			key:   'timestamp_12h_format_invalid'
			value: '15AM'
		},
		Param{
			key:   'timestamp_24h_format'
			value: '16:21'
		},
		Param{
			key:   'timestamp_24h_format_invalid'
			value: '25:12'
		},
	]
}

fn test_get_time() ! {
	sometime := testparams.get_time('when')!
	assert sometime.unixt == 1670271275

	anothertime := testparams.get_time('date')!
	assert anothertime.unixt == 1670198400
}

fn test_get_time_default() ! {
	now := ourtime.now()
	notime := testparams.get_time_default('now', now)!
	assert notime.day() == now.day()
}

fn test_get_time_interval() ! {
	//
}

fn test_get_timestamp_12h_am() ! {
	parsed_time := testparams.get_timestamp('timestamp_12h_format_am')!
	expected := time.Duration(time.hour * 10)
	assert parsed_time == expected
}

fn test_get_timestamp_12h_pm() ! {
	parsed_time := testparams.get_timestamp('timestamp_12h_format_pm')!
	assert parsed_time == time.Duration(time.hour * 20)
}

fn test_get_timestamp_12h_am_minutes() ! {
	parsed_time := testparams.get_timestamp('timestamp_12h_format_am_minutes')!
	assert parsed_time == time.Duration(time.hour * 10 + time.minute * 13)
}

fn test_get_timestamp_12h_pm_minutes() ! {
	parsed_time := testparams.get_timestamp('timestamp_12h_format_pm_minutes')!
	assert parsed_time == time.Duration(time.hour * 20 + time.minute * 7)
}

fn test_get_timestamp_12h_pm_fails() ! {
	mut passed := true
	parsed_time := testparams.get_timestamp('timestamp_12h_format_invalid') or {
		passed = false
		time.Duration(time.hour)
	}
	if passed {
		return error('Did not throw error, it should')
	}
}

fn test_get_timestamp_24h_format() ! {
	parsed_time := testparams.get_timestamp('timestamp_24h_format')!
	assert parsed_time == time.Duration(time.hour * 16 + time.minute * 21)
}

fn test_get_timestamp_24h_format_fails() ! {
	mut passed := true
	parsed_time := testparams.get_timestamp('timestamp_24h_format_invalid') or {
		passed = false
		time.Duration(time.hour)
	}
	if passed {
		return error('Did not throw error, it should')
	}
}

fn test_get_timestamp_default() ! {
	default_duration := time.Duration(time.hour * 8 + time.minute * 30)

	parsed_time := testparams.get_timestamp_default('timestamp_24h_format', default_duration)!
	assert parsed_time == time.Duration(time.hour * 16 + time.minute * 21)

	parsed_time_default := testparams.get_timestamp_default('non_existing_timestamp',
		default_duration)!
	assert parsed_time_default == default_duration
}
