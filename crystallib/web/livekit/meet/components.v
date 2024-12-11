module meet

import time

pub struct Meet {}

pub fn (meet Meet) html() string {
	dollar := '$'
	return $tmpl('./templates/meet.html')
}

pub struct Room {
pub:
	url string
	id           string
	name         string
	creation_time time.Time
	num_participants int
	is_active    bool
	metadata     string
}

pub fn (room Room) html() string {
	dollar := '$'
	return $tmpl('./templates/room.html')
}

pub struct Lobby {
pub:
	rooms []Room
	meetings []Meeting
}

pub struct Meeting {}

pub fn (lobby Lobby) html() string {
	return $tmpl('./templates/lobby.html')
}
// pub struct LiveKitRoom {
//     pub mut:
//         server_url           string
//         token                string
//         audio                bool
//         video                bool
//         screen               bool
//         connect              bool = true
//         options              RoomOptions
//         connect_options      RoomConnectOptions
//         simulate_participants int
//         feature_flags        map[string]bool
//         // room                 Room
// }
