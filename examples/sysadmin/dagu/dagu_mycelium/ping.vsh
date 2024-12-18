#!/usr/bin/env v

import encoding.base64
import freeflowuniverse.crystallib.clients.mycelium { send_msg }

payload := 'im alive'
pk := '738570e732660503756f0ef70670a7940fefef6bcfeafb4be25e6adada155173'

println('sending im alive message')
msg := send_msg(pk, base64.encode_str(payload), false)!
println('message sent id: ${msg.id}')
