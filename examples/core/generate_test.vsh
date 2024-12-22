#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.core.generator.generic

generic.scan(path: '~/code/github/freeflowuniverse/crystallib/examples/core/generatortest', force: true)!
