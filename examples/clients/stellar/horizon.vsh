#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import toml
import toml.to
import json
import os
import freeflowuniverse.crystallib.data.encoderhero
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.blockchain.stellar


mut cl:= stellar.new_horizon_client(.testnet)!

mut a:= cl.get_account("GANUFHCJIDAI347KLXHC6OK3H3Z7YRJQLH6IRBOHLRZ56KJ27LLTXOD7")!
println('account: ${account}')

tx := cl.get_last_transaction('GANUFHCJIDAI347KLXHC6OK3H3Z7YRJQLH6IRBOHLRZ56KJ27LLTXOD7')!
println('last tx: ${tx}')