#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.virt.lima
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.installers.virt.lima as limainstaller
import os

limainstaller.install()!

mut virtmanager := lima.new()!

virtmanager.vm_delete_all()!

// virtmanager.vm_new(reset:true,template:.alpine,name:'alpine',install_crystal:false)!

// virtmanager.vm_new(reset:true,template:.arch,name:'arch',install_crystal:true)!

virtmanager.vm_new(reset: true, template: .ubuntucloud, name: 'hero', install_crystal: false)!
mut vm := virtmanager.vm_get('hero')!

println(vm)

// vm.install_crystal()!

// console.print_debug_title("MYVM", vm.str())
