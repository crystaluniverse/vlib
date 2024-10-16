#!/usr/bin/env -S v -n -w -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.webserver.livekit.meet


osal.load_env_file('${os.dir(@FILE)}/.env') or {
	panic(err)
}

// meet.build(
// 	base_path: '/meet'
// 	livekit_url: os.getenv('LIVEKIT_URL')
// 	livekit_api_key: os.getenv('LIVEKIT_API_KEY')
// 	livekit_api_secret: os.getenv('LIVEKIT_API_SECRET')
// )!

mut app := meet.new(
	livekit_url: os.getenv('LIVEKIT_URL')
	livekit_api_key: os.getenv('LIVEKIT_API_KEY')
	livekit_api_secret: os.getenv('LIVEKIT_API_SECRET')
)

app.run()