module juggler

pub struct Trigger {
	GitTrigger
pub mut:
	id          u32
	name        string
	description string
	object_id   u32
	script_ids  []u32 // the ids of scripts that the trigger triggers
}

pub struct GitTrigger {
	// repository Repository
	action GitAction
}

pub fn (mut j Juggler) is_triggered(trigger Trigger, event Event) bool {
	if trigger.object_id != event.object_id {
		return false
	}
	if trigger.action != event.action {
		return false
	}
	return true
}

pub fn (mut j Juggler) new_trigger(t_ Trigger) !u32 {
	mut t := t_
	return j.osis.generic_new[Trigger](t)!
}

pub fn (mut j Juggler) new_repository(repo_ Repository) !u32 {
	mut repo := repo_
	return j.osis.generic_new[Repository](repo)!
}
