module zola

import vweb
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.osal
import time
import os

const site_name = 'test_site'

fn test_serve() ! {
	mut z := new()!
	mut site := z.new(
		name: zola.site_name
	)!
	spawn site.serve(
		open: false
		port: 9999
	)
	time.sleep(500000000) // sleep so server is running
	mut client := httpconnection.new(
		name: 'test_client'
		url: 'http://localhost:9999'
	)!
	response := client.get()!

	// should fail since website is empty
	assert response == '500 Internal Server Error'
}
