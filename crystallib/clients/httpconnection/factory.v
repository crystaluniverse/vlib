module httpconnection

import net.http
import freeflowuniverse.crystallib.clients.redisclient { RedisURL }

@[params]
pub struct HTTPConnectionArgs {
pub:
	name  string @[required]
	url   string @[required]
	cache bool
	retry int = 1
}

pub fn new(args HTTPConnectionArgs) !&HTTPConnection {
	// mut f := factory

	mut header := http.new_header()

	if args.url.replace(' ', '') == '' {
		panic("URL is empty, can't create http connection with empty url")
	}

	// Init connection
	mut conn := HTTPConnection{
		redis:          redisclient.core_get(RedisURL{})!
		default_header: header
		cache:          CacheConfig{
			disable: !args.cache
			key:     args.name
		}
		retry:          args.retry
		base_url:       args.url.trim('/')
	}
	return &conn
}
