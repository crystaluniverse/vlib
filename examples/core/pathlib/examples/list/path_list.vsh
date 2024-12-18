#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.core.pathlib
import os

const testpath3 = os.dir(@FILE) + '/../../..'

mut p := pathlib.get_dir(path: testpath3)!
// IMPORTANT TO HAVE r'...   the r in front
pl := p.list(regex: [r'.*\.v$'])!
println(pl)
