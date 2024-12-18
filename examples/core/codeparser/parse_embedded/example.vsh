#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.core.codemodel { Struct }

code_path := '${os.dir(@FILE)}/embedding.v'

code := codeparser.parse_v(code_path)!
assert code.len == 2
assert code[0] is Struct
embedder_struct := code[0] as Struct
println(embedder_struct.fields.map('${it.name}: ${it.typ.symbol}'))
