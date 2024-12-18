module chrome

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import os

@[params]
pub struct InstallArgs {
pub mut:
	reset     bool
	uninstall bool
}

pub fn install(args_ InstallArgs) ! {
	mut args := args_
	// base.install()!
	if args.reset || args.uninstall {
		console.print_header('uninstall chrome')
		uninstall()!
		console.print_debug(' - ok')
		if args.uninstall {
			return
		}
	}
	console.print_header('package_install install chrome')
	if !args.reset && osal.done_exists('install_chrome') && exists()! {
		console.print_debug(' - already installed')
		return
	}
	mut url := ''
	if osal.platform() in [.alpine, .arch, .ubuntu] {
		// url = 'https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg'
		panic('not implemented yet')
	} else if osal.platform() == .osx {
		url = 'https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg'
	}
	console.print_debug(' download ${url}')
	_ = osal.download(
		url:        url
		minsize_kb: 5000
		reset:      args.reset
		dest:       '/tmp/googlechrome.dmg'
	)!

	cmd := "
	hdiutil attach /tmp/googlechrome.dmg
	echo ' - copy chrome into app folder'
	echo ' - will now copy all files to Application folder, this can take a while'
	cp -r /Volumes/Google\\ Chrome/Google\\ Chrome.app /Applications/
	sleep 30
	echo ' - copy done'
	hdiutil detach /Volumes/Google\\ Chrome/
	rm -f /tmp/googlechrome.dmg	
	"
	osal.exec(cmd: cmd)!
	console.print_debug(' - copy done to Application folder.')

	if exists()! {
		console.print_debug(' - exists check ok.')
	}

	osal.done_set('install_chrome', 'OK')!
}

@[params]
pub struct ExtensionsInstallArgs {
pub mut:
	extensions string
	default    bool = true
}

pub fn exists() !bool {
	cmd := 'mdfind "kMDItemKind == \'Application\'" | grep "Google Chrome"'
	res := os.execute(cmd)
	if res.exit_code > 0 {
		return false
	}
	return true
}

pub fn install_path() !string {
	cmd := 'mdfind "kMDItemKind == \'Application\'" | grep "Google Chrome"'
	res := os.execute(cmd)
	if res.exit_code > 0 {
		return error("can't find install path")
	}
	return res.output.trim_space()
}

pub fn uninstall() ! {
	cmd := '
	# Quit Google Chrome
	osascript -e \'quit app "Google Chrome"\'

	# Wait a bit to ensure Chrome has completely quit
	sleep 2

	# Remove the Google Chrome Application
	rm -rf "/Applications/Google Chrome.app"

	# Remove Chrome’s Application Support Data
	rm -rf ~/Library/Application\\ Support/Google/Chrome

	# Remove Chrome\'s Caches
	rm -rf ~/Library/Caches/Google/Chrome

	# Delete Chrome Preferences
	rm -rf ~/Library/Preferences/com.google.Chrome.plist

	# Clear Chrome Saved Application State
	rm -rf ~/Library/Saved\\ Application\\ State/com.google.Chrome.savedState

	'
	osal.exec(cmd: cmd)!
}

// # Optional: Empty the Trash
// osascript -e 'tell app "Finder" to empty'
