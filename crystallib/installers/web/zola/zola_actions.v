module zola

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.installers.lang.rust
import freeflowuniverse.crystallib.installers.web.tailwind
import os

pub const version = '0.18.0'

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()} zola -V')
	myversion := res.output.all_after(' ')
	if res.exit_code == 0 {
		v := texttools.version(myversion)
		if v != texttools.version(version) {
			return false
		}
		return true
	}
	return false
}

fn install() ! {
	console.print_header('install zola')

	// make sure we install base on the node
	base.install()!

	mut tw := tailwind.get()!
	tw.install()!

	mut url := ''
	if osal.is_linux() {
		url = 'https://github.com/getzola/zola/releases/download/v${version}/zola-v${version}-x86_64-unknown-linux-gnu.tar.gz'
	} else if osal.is_osx_arm() {
		url = 'https://github.com/getzola/zola/releases/download/v${version}/zola-v${version}-aarch64-apple-darwin.tar.gz'
	} else if osal.is_osx_intel() {
		url = 'https://github.com/getzola/zola/releases/download/v${version}/zola-v${version}-x86_64-apple-darwin.tar.gz'
	} else {
		return error('unsupported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 5000
		reset:      true
		expand_dir: '/tmp/zolaserver'
	)!

	mut zolafile := dest.file_get('zola')! // file in the dest

	osal.cmd_add(
		source: zolafile.path
	)!

	console.print_header('Zola Installed')
}

// install zola will return true if it was already installed
fn build() ! {
	rust.install()!
	console.print_header('install zola')
	cmd := '
    source ~/.cargo/env
    cd /tmp
    rm -rf zola
    git clone https://github.com/getzola/zola.git
    cd zola
    cargo install --path . --locked
    zola --version
    cargo build --release --locked --no-default-features --features=native-tls
    cp target/release/zola ~/.cargo/bin/zola
    '
	osal.execute_stdout(cmd)!
	osal.done_set('install_zola', 'OK')!
	console.print_header('zola installed')
}

fn destroy() ! {
}
