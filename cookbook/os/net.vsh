#!/usr/bin/env -S v -n -w -enable-globals run

import os
import freeflowuniverse.crystallib.osal

println(osal.tcp_port_test(address: '65.21.132.119', port: 22, timeout: 1000))
