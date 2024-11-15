module livekit

import net.http
import json

// // pub struct Client {
// // pub:
// // 	host  string
// // 	token string
// // }

// // pub struct Room {
// // pub mut:
// // 	sid              string
// // 	name             string
// // 	empty_timeout    string
// // 	max_participants string
// // 	creation_time    string
// // 	turn_password    string
// // 	metadata         string
// // 	num_participants u32
// // 	active_recording bool
// // }

// pub struct ParticipantInfo {
// pub mut:
// 	sid          string
// 	identity     string
// 	name         string
// 	state        string
// 	tracks       []TrackInfo
// 	metadata     string
// 	joined_at    i64
// 	permission   ParticipantPermission
// 	is_publisher bool
// }

// pub struct TrackInfo {
// pub mut:
// 	sid         string
// 	typ         string @[json: 'type']
// 	source      string
// 	name        string
// 	mime_type   string
// 	muted       bool
// 	width       u32
// 	height      u32
// 	simulcast   bool
// 	disable_dtx bool
// 	layers      []VideoLayer
// }

// pub struct ParticipantPermission {
// pub mut:
// 	can_subscribe    bool
// 	can_publish      bool
// 	can_publish_data bool
// }

// pub struct VideoLayer {
// pub mut:
// 	quality string
// 	width   u32
// 	height  u32
// }

// // Helper method to make POST requests to LiveKit API
// fn (client Client) make_post_request(url string, body string) !http.Response {
// 	mut headers := http.new_header()
// 	headers.add_custom('Authorization', 'Bearer ${client.token}')!
// 	headers.add_custom('Content-Type', 'application/json')!

// 	req := http.Request{
// 		method: http.Method.post
// 		url:    url
// 		data:   body
// 		header: headers
// 	}
// 	return req.do()!
// }

// pub struct CreateRoomArgs {
// pub:
// 	name string
// 	empty_timeout u32
// 	max_participants u32
// 	metadata string
// }

// // RoomService API methods
// pub fn (client Client) create_room(args CreateRoomArgs) !Room {
// 	body := json.encode(args)
// 	url := '${client.host}/twirp/livekit.RoomService/CreateRoom'
// 	response := client.make_post_request(url, body)!

// 	return json.decode(Room, response.body)!
// }

// // pub fn (client Client) list_rooms(names []string) ![]Room {
// // 	body := json.encode({
// // 		'names': names
// // 	})
// // 	url := '${client.host}/twirp/livekit.RoomService/ListRooms'
// // 	response := client.make_post_request(url, body)!

// // 	return json.decode([]Room, response.body)!
// // }

// pub fn (client Client) delete_room(room_name string) ! {
// 	body := json.encode({
// 		'room': room_name
// 	})
// 	url := '${client.host}/twirp/livekit.RoomService/DeleteRoom'
// 	_ := client.make_post_request(url, body)!
// }

// pub fn (client Client) list_participants(room_name string) ![]ParticipantInfo {
// 	body := json.encode({
// 		'room': room_name
// 	})
// 	url := '${client.host}/twirp/livekit.RoomService/ListParticipants'
// 	response := client.make_post_request(url, body)!

// 	return json.decode([]ParticipantInfo, response.body)!
// }

// pub fn (client Client) get_participant(room_name string, identity string) !ParticipantInfo {
// 	body := json.encode({
// 		'room':     room_name
// 		'identity': identity
// 	})
// 	url := '${client.host}/twirp/livekit.RoomService/GetParticipant'
// 	response := client.make_post_request(url, body)!

// 	return json.decode(ParticipantInfo, response.body)!
// }

// pub fn (client Client) remove_participant(room_name string, identity string) ! {
// 	body := json.encode({
// 		'room':     room_name
// 		'identity': identity
// 	})
// 	url := '${client.host}/twirp/livekit.RoomService/RemoveParticipant'
// 	_ := client.make_post_request(url, body)!
// }

// pub struct MutePublishedTrackArgs {
// pub:
// 	room_name string
// 	identity string
// 	track_sid string
// 	muted bool
// }

// pub fn (client Client) mute_published_track(args MutePublishedTrackArgs) ! {
// 	body := json.encode(args)
// 	url := '${client.host}/twirp/livekit.RoomService/MutePublishedTrack'
// 	_ := client.make_post_request(url, body)!
// }

// pub struct UpdateParticipantArgs {
// pub:
// 	room_name string @[json: 'room']
// 	identity string
// 	metadata string
// 	permission ParticipantPermission
// }

// pub fn (client Client) update_participant(args UpdateParticipantArgs) ! {
// 	body := json.encode(args)
// 	url := '${client.host}/twirp/livekit.RoomService/UpdateParticipant'
// 	_ := client.make_post_request(url, body)!
// }

// pub struct UpdateRoomMetadataArgs {
// pub:
// 	room_name string @[json: 'room']
// 	metadata string
// }

// pub fn (client Client) update_room_metadata(args UpdateRoomMetadataArgs) ! {
// 	body := json.encode(args)
// 	url := '${client.host}/twirp/livekit.RoomService/UpdateRoomMetadata'
// 	_ := client.make_post_request(url, body)!
// }

// pub struct SendDataArgs {
// pub:
// 	room_name string @[json: 'room']
// 	data []u8
// 	kind string
// 	destination_identities []string
// }

// pub fn (client Client) send_data(args SendDataArgs) ! {
// 	body := json.encode(args)
// 	url := '${client.host}/twirp/livekit.RoomService/SendData'
// 	_ := client.make_post_request(url, body)!
// }
