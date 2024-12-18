#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.osal { ping }

assert ping(address: '338.8.8.8')! == .unknownhost
assert ping(address: '8.8.8.8')! == .ok
assert ping(address: '18.8.8.8')! == .timeout
