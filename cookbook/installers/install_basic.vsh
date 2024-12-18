#!/usr/bin/env -S v -n -w -enable-globals run

import os
import freeflowuniverse.crystallib.installers.web.tailwind as tailwindinstaller
import freeflowuniverse.crystallib.installers.web.mdbook as mdbookinstaller
import freeflowuniverse.crystallib.installers.web.zola as zolainstaller
import freeflowuniverse.crystallib.installers.lang.rust as rustinstaller
import freeflowuniverse.crystallib.installers.lang.golang as goinstaller
import freeflowuniverse.crystallib.installers.sysadmintools.restic as resticinstaller
import freeflowuniverse.crystallib.installers.sysadmintools.rclone as rcloneinstaller
import freeflowuniverse.crystallib.installers.virt.podman as podmaninstaller

mut reset := false

// reset=true

// tailwindinstaller.install(reset:reset)!
// mdbookinstaller.install(reset:reset)!
// zolainstaller.install(reset:reset)!
// rustinstaller.install(reset:reset)!
// goinstaller.install(reset:reset)!
// resticinstaller.install(reset:reset)!
// rcloneinstaller.install(reset:reset)!
podmaninstaller.install(reset: reset)!
