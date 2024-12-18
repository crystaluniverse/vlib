module openai

// run heroscript starting from path, text or giturl
//```
// !!OpenAIclient.define
//     name:'default'
//	   openaikey: ''
//     description:'...'
//```	
pub fn heroplay(mut plbook playbook.PlayBook) ! {
	for mut action in plbook.find(filter: 'openaiclient.define')! {
		mut p := action.params
		instance := p.get_default('instance', 'default')!
		// cfg.keyname = p.get('keyname')!
		mut cl := get(instance,
			openaikey:   p.get('openaikey')!
			description: p.get_default('description', '')!
		)!
		cl.config_save()!
	}
}

//>TODO: this needs to be extended to chats, ...
