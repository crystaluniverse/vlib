#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.data.paramsparser { Params, parse }
import time

totalnr := 1000000

// some performance tests
mut res := []Params{}
mut sw := time.new_stopwatch()
for i in 0 .. totalnr {
	mut text := "arg${i} arg2 color:red${i} priority:'incredible' description:'with spaces, lets see if ok'"
	mut p := parse(text) or { panic(err) }
	res << p
}
sw.stop()
mut elapsed := sw.elapsed()
println(elapsed)
sw.restart()
incl_test := ['description:*see*']
mut foundnr := 0
for i in 0 .. totalnr {
	mut p2 := res[i]
	e := p2.filter_match(include: incl_test)!
	f := p2.filter_match(include: ['arg100'])!
	if f {
		foundnr += 1
	}
}
assert foundnr == 1
elapsed = sw.elapsed()
println(elapsed)
// sw.restart()	

mbused := 600.0
bytesused := mbused * 1000 * 1000
bytes_param := bytesused / totalnr
println('bytes used per param: ${bytes_param}')
println('nr of founds: ${foundnr}')

// sleep(Duration(60 * time.minute))

// 600 bytes per params for 1m records
// TODO: not sure needs to be redone
// takes 0.9 sec to walk over 1million records
