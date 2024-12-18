#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.baobab.generator
import freeflowuniverse.crystallib.core.codemodel { Struct }
import freeflowuniverse.crystallib.core.codeparser
import os

const dest_dir = '${os.dir(@FILE)}/project_manager'

if os.exists(dest_dir) {
	os.rmdir_all(dest_dir)!
}

// lets parse the struct for which we will generate code
story_model := codeparser.parse_v('${os.dir(@FILE)}/source/story_model.v')!
story_struct := story_model[0] as Struct

actor_module := generator.generate_actor('ProjectManager', [story_struct])!
actor_module.write_v(dest_dir, format: true, overwrite: true)!
