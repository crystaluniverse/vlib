module base

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import os

const scriptspath = os.dir(@FILE) + '/../../../scripts'

fn script_write(mybase string, name string, cmd_ string) ! {
	cmd := texttools.dedent(cmd_)
	mut out := '${mybase}\n'
	for line in cmd.split_into_lines() {
		out += '${line}\n'
	}
	mut p := pathlib.get_file(path: '${scriptspath}/${name}.sh', create: true)!
	p.write(out)!
	os.chmod(p.path, 0o777)!
}

pub fn bash_installers_package() !string {
	l := '
		1_init.sh
		2_myplatform.sh	
		3_gittools.sh
		4_package.sh
		5_exec.sh
		6_reset.sh
		7_zinit.sh
		8_osupdate.sh
		9_redis.sh
		10_installer_v.sh
		11_installer_crystallib.sh
		12_installer_hero.sh
		13_s3.sh
		20_installers.sh
	'
	mut out := ''
	for mut name in l.split_into_lines() {
		name = name.trim_space()
		if name == '' {
			continue
		}
		mut p := pathlib.get_file(path: '${scriptspath}/lib/${name}', create: false)!
		c := p.read()!
		out += c
	}

	script_write(out, 'baselib', '')!

	script_write(out, 'installer', "
		freeflow_dev_env_install
		echo 'V & CRYSTAL INSTALL OK'
		")!

	script_write(out, 'build_hero', "
		hero_build
		echo 'BUILD HERO OK'
		")!

	script_write(out, 'install_hero', "
		hero_install
		echo 'INSTALL HERO OK'
		")!

	script_write(out, 'githubactions', "
		hero_build
		crystal_test
		hero_upload
		echo 'OK'
		")!

	mut p4 := pathlib.get_dir(path: '${scriptspath}', create: false)!
	return p4.path
}
