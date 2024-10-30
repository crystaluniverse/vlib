module mediacms

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.installers.docker
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console

// install mediacms will return true if it was already installed
pub fn build(myargs Config) ! {
	console.print_header('build mediacms')

	checkplatform()!

	base.install()!
	docker.install()!

	mut gs := gittools.get()!
	mut repo := gs.get_repo(
		url: 'https://github.com/mediacms-io/mediacms'
		pull: true
		reset: true
	)!
	dest := repo.get_path()!

	pathlib.template_write($tmpl('templates/Dockerfile.py'), '${dest}/Dockerfile.py',
		myargs.reset)!
	pathlib.template_write($tmpl('templates/cms/settings.py'), '${dest}/cms/settings.py',
		myargs.reset)!
	pathlib.template_write($tmpl('templates/docker-compose.yaml'), '${dest}/docker-compose.yaml',
		myargs.reset)!
	pathlib.template_write($tmpl('templates/frontend/src/templates/config/installation/contents.config.js'),
		'${dest}/frontend/src/templates/config/installation/contents.config.js', myargs.reset)!
	pathlib.template_write($tmpl('templates/frontend/src/templates/config/installation/features.config.js'),
		'${dest}/frontend/src/templates/config/installation/features.config.js', myargs.reset)!
	pathlib.template_write($tmpl('templates/frontend/src/templates/config/installation/pages.config.js'),
		'${dest}/frontend/src/templates/config/installation/pages.config.js', myargs.reset)!
	pathlib.template_write($tmpl('templates/frontend/src/templates/config/installation/site.config.js'),
		'${dest}/frontend/src/templates/config/installation/site.config.js', myargs.reset)!

	// install mediacms if it was already done will return true

	cmd := '
    source ${osal.profile_path()} //source the go path
    cd ${dest}
    docker-compose build


    '
	osal.execute_stdout(cmd)!
}
