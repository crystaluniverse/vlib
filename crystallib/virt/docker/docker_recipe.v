module docker

import freeflowuniverse.crystallib.data.paramsparser { Params }
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.osal { exec, file_write }
import crypto.md5
import v.embed_file
import os
import freeflowuniverse.crystallib.ui.console

// only 2 supported for now
pub enum PlatformType {
	alpine
	ubuntu
}

type RecipeItem = AddFileEmbeddedItem
	| CmdItem
	| CopyItem
	| EntryPointItem
	| EnvItem
	| ExposeItem
	| FromItem
	| PackageItem
	| RunItem
	| VolumeItem
	| WorkDirItem
	| ZinitItem

pub struct RecipeArgs {
pub:
	name   string
	prefix string // string (e.g. despiegk/ or myimage registry-host:5000/despiegk/) is added to the name when pushing
	// also exists on docker engine level, if not used here will come from the docker engine level
	tag      string //(default is 'latest' but can be a version nr)
	platform PlatformType
	zinit    bool = true
}

// params
// ```
// name     string
// prefix 	 string (e.g. despiegk/ or myimage registry-host:5000/despiegk/) is added to the name when pushing
//					also exists on docker engine level, if not used here will come from the docker engine level
// tag		 string (default is 'latest' but can be a version nr)
// platform PlatformType
// zinit    bool = true
// ```
pub fn (mut e DockerEngine) recipe_new(args RecipeArgs) DockerBuilderRecipe {
	if args.name == '' {
		panic('name cannot be empty.')
	}
	return DockerBuilderRecipe{
		engine:   &e
		platform: args.platform
		name:     args.name
		zinit:    args.zinit
		tag:      args.tag
		prefix:   args.prefix
	}
}

@[heap]
pub struct DockerBuilderRecipe {
pub mut:
	name     string
	prefix   string
	tag      string
	params   Params
	files    []embed_file.EmbedFileData
	engine   &DockerEngine @[str: skip]
	items    []RecipeItem
	platform PlatformType
	zinit    bool
}

// delete the working directory
pub fn (mut b DockerBuilderRecipe) delete() ! {
	// exec(cmd:)
	panic('implement')
}

pub fn (mut b DockerBuilderRecipe) render() !string {
	b.check_from_statement()!
	b.check_conf_add()!
	mut items := []string{}
	mut zinitexists := false
	for mut item in b.items {
		item_str := match mut item {
			FromItem {
				item.check()!
				item.render()!
			}
			RunItem {
				item.check()!
				item.render()!
			}
			PackageItem {
				item.check()!
				item.render()!
			}
			CmdItem {
				item.check()!
				item.render()!
			}
			AddFileEmbeddedItem {
				item.check()!
				item.render()!
			}
			EntryPointItem {
				item.check()!
				item.render()!
			}
			EnvItem {
				item.check()!
				item.render()!
			}
			WorkDirItem {
				item.check()!
				item.render()!
			}
			CopyItem {
				item.check()!
				item.render()!
			}
			ExposeItem {
				item.check()!
				item.render()!
			}
			VolumeItem {
				item.check()!
				item.render()!
			}
			ZinitItem {
				zinitexists = true
				item.check()!
				item.render()!
			}
		}
		items << item_str
	}
	if zinitexists {
		// means there is a zinit, we need to add the directory for zinit
		items << 'COPY zinit /etc/zinit\n'
	}
	return items.join('\n')
}

fn (mut b DockerBuilderRecipe) check_from_statement() ! {
	mut fromfound := false
	for item3 in b.items {
		if item3 is FromItem {
			fromfound = true
		}
	}
	if fromfound == false {
		// put automatically alpine or ubuntu in
		// console.print_debug(" *** put automatically alpine or ubuntu in")
		if b.platform == .alpine {
			b.items.prepend(FromItem{ recipe: &b, image: 'alpine', tag: 'latest' })
		} else {
			b.items.prepend(FromItem{ recipe: &b, image: 'ubuntu', tag: 'latest' })
		}
	}
}

fn (mut b DockerBuilderRecipe) check_conf_add() ! {
	// we need to make sure we insert it after the last FromItem
	mut lastfromcounter := 0
	mut counter := 0
	for item3 in b.items {
		if item3 is FromItem {
			lastfromcounter = counter
		}
		counter += 1
	}
	for item in b.items {
		if item is AddFileEmbeddedItem {
			if item.source == 'conf.sh' {
				return
			}
		}
	}
	b.items.insert(lastfromcounter + 1, AddFileEmbeddedItem{
		recipe:      &b
		source:      'conf.sh'
		dest:        '/conf.sh'
		check_embed: false
	})
}

pub fn (mut b DockerBuilderRecipe) path() string {
	destpath := '${b.engine.buildpath}/${b.name}'
	return destpath
}

pub fn (mut b DockerBuilderRecipe) build(reset bool) ! {
	dockerfilecontent := b.render()!

	destpath := b.path()
	os.mkdir_all(destpath)!
	file_write('${destpath}/Dockerfile', dockerfilecontent)!
	for item in b.files {
		filename := item.path.all_after_first('/')
		file_write('${destpath}/${filename}', item.to_string())!
	}
	confsh := '
		export NAME="${b.name}"
	'
	file_write('${destpath}/conf.sh', texttools.dedent(confsh))!
	if b.engine.localonly {
		b.tag = 'local'
	} else {
		b.tag = 'latest'
	}
	mut bplatform := '--platform='
	for plat in b.engine.platform {
		if plat == .linux_arm64 {
			bplatform += ',linux/arm64'
		}
		if plat == .linux_amd64 {
			bplatform += ',linux/amd64'
		}
		bplatform = bplatform.replace('=,', '=').trim(',')
	}
	mut nocache := ''
	if b.engine.cache == false || reset {
		nocache = '--no-cache'
	}

	mut bpush := ''
	if b.engine.push == true {
		bpush = '--push'
	}
	cmd := '
		set -ex
		cd ${destpath}
		docker buildx build . -t ${b.name}:${b.tag} --ssh default=\${SSH_AUTH_SOCK} ${nocache} ${bplatform} ${bpush}
		'

	mut cmdshell := 'set -ex\ncd ${destpath}\ndocker rm ${b.name} -f > /dev/null 2>&1\ndocker run --name ${b.name} '
	if b.zinit { // means zinit is in docker
		cmdshell += '-d'
		// cmdshell += '   -v ${destpath}/zinit:/etc/zinit \\\n' //we don\t want to add zinit any more
	} else {
		cmdshell += '-it \\\n'
	}
	cmdshell += '    -v ${destpath}:/src \\\n'
	cmdshell += '    -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock \\\n'
	cmdshell += '    -e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" \\\n'
	cmdshell += '    --privileged \\\n'
	cmdshell += '    --hostname ${b.name} ${b.name}:${b.tag}'
	if b.zinit {
		cmdshell += '\n\ndocker exec -ti ${b.name} /bin/shell.sh'
	} else {
		cmdshell += " '/bin/shell.sh'\n"
	}
	cmdshell += '\ndocker rm ${b.name} -f > /dev/null 2>&1\n'
	// console.print_debug(cmdshell)

	mut tohash := dockerfilecontent + b.name + cmdshell + cmd
	for mut item in b.items {
		if mut item is AddFileEmbeddedItem {
			c := item.getcontent()!
			tohash += c
		}
	}

	image_exists := b.engine.image_exists(repo: b.name)!
	hashnew := md5.hexhash(tohash)

	if image_exists && reset == false && osal.done_exists('build_${b.name}') {
		hashlast := osal.done_get('build_${b.name}') or { '' }
		if hashnew == hashlast {
			console.print_debug('\n ** BUILD ALREADY DONE FOR ${b.name.to_upper()}\n')
			return
		}
	}

	file_write('${destpath}/shell.sh', cmdshell)!
	os.chmod('${destpath}/shell.sh', 0o777)!

	exec(scriptpath: '${destpath}/build.sh', cmd: cmd, scriptkeep: true)!

	osal.done_set('build_${b.name}', hashnew)!
}
