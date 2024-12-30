module osal

import log

__global (
	memdb shared map[string]string
)

pub fn memdb_set(key string, val string) {
	lock memdb {
		memdb[key] = val
	}
}

pub fn memdb_get(key string) string {
	lock memdb {
		return memdb[key] or { return '' }
	}
	return ''
}

pub fn memdb_exists(key string) bool {
	if memdb_get(key).len > 0 {
		return true
	}
	return false
}

// Returns a logger object and allows you to specify via environment argument OSAL_LOG_LEVEL the debug level
pub fn get_logger() log.Log {
	log_level := env_get_default('OSAL_LOG_LEVEL', 'info')
	mut logger := &log.Log{}
	logger.set_level(match log_level.to_lower() {
		'debug' { .debug }
		'info' { .info }
		'warn' { .warn }
		'error' { .error }
		else { .info }
	})
	return *logger
}
