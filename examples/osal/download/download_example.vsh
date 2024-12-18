#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.osal { download }

mut p := download(
	url:        'https://cdnjs.cloudflare.com/ajax/libs/echarts/5.4.3/@name'
	name:       'echarts.min.js'
	reset:      false
	dest:       '/tmp/@name'
	minsize_kb: 1000
	maxsize_kb: 5000
)!

println(p)
