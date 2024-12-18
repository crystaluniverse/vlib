module pacman

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import os

// checks if a certain version or above is installed
fn installed() !bool {
	return osal.done_exists('install_pacman')
}

// use https://archlinux.org/mirrorlist/

fn install() ! {
	console.print_header('install pacman')

	if osal.platform() == .arch {
		return
	}

	if osal.platform() != .ubuntu {
		return error('only ubuntu supported for this installer.')
	}

	cmd := '

    mkdir -p /etc/pacman.d/gnupg

    '
	osal.execute_stdout(cmd)!

	dest := '/etc/pacman.conf'
	c := $tmpl('templates/pacman.conf')
	os.write_file(dest, c)!

	dest2 := '/etc/pacman.d/mirrorlist'
	c2 := $tmpl('templates/mirrorlist')
	pathlib.template_write(c2, dest2, true)!

	osal.package_install('
       arch-install-scripts
       pacman-package-manager
    ')!

	url := 'https://gist.githubusercontent.com/despiegk/e56403ecba40f6057251c6cc609c4cf2/raw/1822c921e7282c491d8ac35f3719f51e234f1cbf/gistfile1.txt'
	mut gpg_dest := osal.download(
		url:        url
		minsize_kb: 1000
		reset:      true
	)!

	cmd2 := '

    mkdir -p  /tmp/keyrings
    cd /tmp/keyrings
    
    wget https://archlinux.org/packages/core/any/archlinux-keyring/download -O archlinux-keyring.tar.zst
    tar -xvf archlinux-keyring.tar.zst

    mkdir -p /usr/share/keyrings
    cp usr/share/pacman/keyrings/archlinux.gpg /usr/share/keyrings/

    pacman-key --init
    pacman-key --populate archlinux  

    gpg --import ${gpg_dest.path}

    # Clean up
    rm -f pacman_keyring.asc

    #pacman-key --refresh-keys
    pacman-key --update
    
    rm -rf /tmp/keyrings

    '
	osal.execute_stdout(cmd2)!

	// TODO: is not working well, is like it doesn;t write in right location
	osal.done_set('install_pacman', 'OK')!

	console.print_header('install done')
}

fn destroy() ! {
	osal.done_delete('install_pacman')!

	osal.package_remove('
       arch-install-scripts
       pacman-package-manager
    ')!

	// TODO: will need to remove more
	osal.rm('
       pacman
       /etc/pacman.d
       /var/cache/pacman
    ')!
}
