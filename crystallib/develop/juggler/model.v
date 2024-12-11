module juggler

import freeflowuniverse.crystallib.core.texttools
import time

pub enum GitAction {
	push
	commit
	manual
}

pub struct Event {
pub mut:
	id        u32
	subject   string
	object_id u32
	commit    Commit
	time      time.Time
	action    GitAction
}

pub struct GitEvent {
pub mut:
	id         u32
	repository Repository
	commit     Commit
	time       time.Time
	action     GitAction
}

pub fn (e Event) name() string {
	// if e is GitEvent {
	return 'git push to'
	// } else {
	// 	panic('implement')
	// }
}

pub fn (e Event) category() string {
	// if e is GitEvent {
	return e.category()
	// } else {
	// 	panic('implement')
	// }
}

pub fn (mut j Juggler) event_card(event Event) !string {
	repo := j.osis.generic_get[Repository](event.object_id)!
	return event.card(repo)
}

pub fn (event Event) card(repository Repository) string {
	event_receiver := repository.full_name()
	event_action := 'Push'
	event_sub_1 := if event.commit.hash.len > 0 {
		event.commit.hash[event.commit.hash.len - 7..]
	} else {
		''
	}
	return $tmpl('../../../../webcomponents/webcomponents/tailwind/juggler_templates/event_card.html')
}

pub fn (mut j Juggler) row(play Play) string {
	script := j.osis.generic_get[Script](play.script_id) or { panic(err) }
	event := j.osis.generic_get[Event](play.event_id) or { panic(err) }
	status_color := match play.status {
		.starting { 'yellow-500' }
		.success { 'emerald-500' }
		.running { 'amber-500' }
		.error { 'red-500' }
	}
	return $tmpl('../../../../webcomponents/webcomponents/tailwind/juggler_templates/play_row.html')
}

pub fn (e GitEvent) category() string {
	return 'git push'
}

pub struct CustomEvent {
pub:
	time time.Time
}

pub fn (e GitEvent) name() string {
	return 'git push ${e.repository.full_name()}'
}

pub struct Script {
pub mut:
	id          u32
	name        string
	description string
	url         string
	path        string
	status      string
	category    ScriptCategory
}

pub fn (s Script) id() string {
	return s.name.replace('.', '_')
}

// pub fn (play Play) id() string {
// 	return '${play.event_id}_${texttools.name_fix(play.script_id)}'
// }

// a play of a script due to a trigger that occurs
pub struct Play {
pub mut:
	id         u32
	script_id  u32 // id of script that is played
	event_id   u32 // id of event that triggered the play
	trigger_id u32
	status     Status    // status of the play
	output     string    // output of the play
	start      time.Time // time the play started
	end        time.Time // time the play ended
}

pub fn (p Play) duration() time.Duration {
	return p.end - p.start
}

pub enum Status {
	starting
	running
	success
	error
}
