#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.sms { StatusTypes, new_sms_client }
import os
import log

sid := os.getenv('TWILIO_ACCOUNT_SID')
token := os.getenv('TWILIO_AUTH_TOKEN')
source := os.getenv('TWILIO_NUMBER')

mut logger := log.Log{}
logger.set_level(.info)

cred := sms.Credentials{
	sid:    sid
	token:  token
	source: source
}
mut client := new_sms_client(cred, mut logger)!

msg := sms.Message{
	content:     'hello_world'
	destination: '+201005001050'
}

res := client.send(msg) or {
	client.logger.error('failed to send message: ${err}')
	exit(1)
}

if res.level == StatusTypes.error {
	client.logger.error('${res.content}: ${res.more_info}')
} else {
	client.logger.info('${res.content}: ${res.more_info}')
}
