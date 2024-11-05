module webdav

import vweb

fn test_run() {
	app := new_app('/tmp/webdav')!
	vweb.run(app, 8080)
}
