#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.crypt.secrets

secrets.delete_passwd()!
r := secrets.encrypt('aaa')!
println(r)
assert 'aaa' == secrets.decrypt(r)!
