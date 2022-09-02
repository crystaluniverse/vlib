module markdown
import texttools

pub struct Action{
pub mut:
	content string
	remarks string
	name string
	params texttools.Params
}


fn (mut action Action) process()?{

	mo := texttools.macro_parse(action.content)?
	action.name = mo.cmd
	action.params = mo.params
	
}

fn ( action Action) wiki() string{
	return action.content
	
}

fn ( action Action) html() string{
	return action.wiki()
}

fn ( action Action) str() string{
	p := "${action.params}"
	return "**** ACTION ${action.name}\n${texttools.indent(p,"    ")}"
}


//is set of actions in a codeblock
pub struct Actions{
pub mut:
	content string
	actions []Action
}


fn (mut actions Actions) process()?{
	for mut action in actions.actions{
		action.process()?
	}
	
}

fn ( actions Actions) wiki() string{
	return actions.content
	
}

fn ( actions Actions) html() string{
	return actions.wiki()
}

fn ( actions Actions) str() string{
	mut out := "**** ACTIONS\n"
	for action in actions.actions{
		out+= "  ** ACTION ${action.name}\n"
	}
	return out
}

// fn (mut actions Actions) action_add(a Action){
// 	println(a)
// }