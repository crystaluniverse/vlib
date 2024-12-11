#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import toml
import toml.to
import json
import os
import freeflowuniverse.crystallib.data.encoderhero
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.blockchain


heropath := '/Users/despiegk1/private_new/tft/data/hero'


mut bc:=blockchain.get()!

blockchain.play(path:heropath)!

println(bc)