#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run


import freeflowuniverse.crystallib.vfs.webdav
import os


webdav.start(path:"/tmp")!