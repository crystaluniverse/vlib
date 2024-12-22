#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.openai
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base

console.print_header('OPENAI Example.')

// Check for required environment variables
key := os.getenv('OPENAIKEY')
if key == '' {
	eprintln('Error: OPENAIKEY environment variable is not set')
	eprintln('Please set it using: export OPENAIKEY=your-yourkey')
	exit(1)
}

heroscript := "
!!openai.configure
    name:'default'
    openaikey:'${key}'
"

openai.play(heroscript: heroscript)!


mut ai := openai.get()!

models := ai.list_models()!

println(models)


// mut msg := []openai.Message{}
// msg << openai.Message{
// 	role:    openai.RoleType.user
// 	content: 'Say this is a test!'
// }
// mut msgs := openai.Messages{
// 	messages: msg
// }
// res := ai.chat_completion(openai.ModelType.gpt_3_5_turbo, msgs)!
// print(res)


