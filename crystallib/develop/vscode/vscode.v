module vscode

import freeflowuniverse.crystallib.osal
import os

pub struct VSCodeHelper {
	pub mut:
		install_if_not_exists bool
		path string
}

pub fn new(path string) VSCodeHelper {
	return VSCodeHelper{
		path: path
	}
}

// Open Visual Studio Code at the specified path.
// If the path is not provided, it defaults to the current working directory.
pub fn (mut self VSCodeHelper) open() ! {
	if self.path == '' {
		self.path = os.getwd()
	}

	self.check_installation()!

	if !os.exists(self.path) {
		return error('Cannot open Visual Studio Code: path not found: ${self.path}')
	}

	cmd := '${self.get_executable_binary()} ${self.path}'
	osal.execute_interactive(cmd)!
}

// Get the executable binary for Visual Studio Code.
fn (mut self VSCodeHelper) get_executable_binary() string {
	if self.is_installed() {
		if osal.cmd_exists('vscode') {
			return 'vscode'
		}
		return 'code'
	}
	return ''
}

// Check if Visual Studio Code is installed.
pub fn (mut self VSCodeHelper) is_installed() bool {
	return osal.cmd_exists('vscode') || osal.cmd_exists('code')
}

// Check the installation status of Visual Studio Code.
// If not installed and the flag is set, attempt to install it.
pub fn (mut self VSCodeHelper) check_installation() ! {
	if !self.is_installed() {
		if self.install_if_not_exists {
			// Uncomment and implement the installation logic if needed
			// vscodeinstaller.install()!
			// return check_installation()
			return error('Visual Studio Code is not installed.\nPlease see https://code.visualstudio.com/download')
		}
		return error('Visual Studio Code is not installed.\nPlease see https://code.visualstudio.com/download')
	}
}
