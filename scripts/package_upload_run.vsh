#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

// #!/usr/bin/env -S v -n -w -enable-globals run
import os
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.builder
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console

const mydir = os.dir(@FILE)

mypath := base.bash_installers_package()!

res := os.execute('bash ${mypath}/install_base.sh')
// println(res)
if res.exit_code > 0 {
	// println(cmd)
	println('Could not run the installer, just to check if there are no syntax errors.\n${res.output}')
	exit(1)
}

console.print_debug('packaged succesfully')

mut b := builder.new()!

mut myserver := os.getenv('SERVER')
if myserver == '' {
	console.print_stderr("can't find SERVER env, do 'export SERVER=...'")
	exit(1)
}

mut n := b.node_new(ipaddr: 'root@${myserver}')!

console.print_debug('upload installer')
n.upload(source: '${mydir}/build_hero.sh', dest: '/tmp/build_hero.sh')!
console.print_debug('exec installer')
n.exec(cmd: '/tmp/build_hero.sh')!
