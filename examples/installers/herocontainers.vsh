#!/usr/bin/env -S v -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.lang.golang
import freeflowuniverse.crystallib.installers.virt.podman as podman_installer
import freeflowuniverse.crystallib.installers.virt.buildah as buildah_installer

mut podman_installer0 := podman_installer.get()!
mut buildah_installer0 := buildah_installer.get()!

// podman_installer0.destroy()! //will remove all

podman_installer0.install()!
buildah_installer0.install()!
