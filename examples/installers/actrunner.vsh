#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.installers.sysadmintools.actrunner
import freeflowuniverse.crystallib.installers.virt.herocontainers

actrunner.install()!
// herocontainers.start()!
