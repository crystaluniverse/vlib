#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import vweb
import os
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.web.caddy as caddyinstaller
import freeflowuniverse.crystallib.core.playbook

// install caddy
heroscript := "
!!caddy.install
    xcaddy:true
    restart:true
    reset:true
    homedir:'/root/www'
    xcaddy:1

"

// default plugins are github.com/mholt/caddy-webdav,github.com/mohammed90/caddy-git-fs,github.com/abiosoft/caddy-exec,github.com/greenpau/caddy-security if xcaddy used

mut plbook := playbook.new(text: heroscript)!
caddyinstaller.play(mut plbook)!
