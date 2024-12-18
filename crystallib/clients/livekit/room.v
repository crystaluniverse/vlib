module livekit

import net.http
import json

@[params]
pub struct ListRoomsParams {
	names []string
}

pub struct ListRoomsResponse {
pub:
	rooms []Room
}

pub fn (c Client) list_rooms(params ListRoomsParams) !ListRoomsResponse {
	// Prepare request body
	request := params
	request_json := json.encode(request)

	// create token and give grant to list rooms
	mut token := c.new_access_token()!
	token.grants.video.room_list = true

	// make POST request
	url := '${c.url}/twirp/livekit.RoomService/ListRooms'
	// Configure HTTP request
	mut headers := http.new_header_from_map({
		http.CommonHeader.authorization: 'Bearer ${token.to_jwt()!}'
		http.CommonHeader.content_type:  'application/json'
	})

	response := http.fetch(http.FetchConfig{
		url:    url
		method: .post
		header: headers
		data:   request_json
	})!

	if response.status_code != 200 {
		return error('Failed to list rooms: ${response.status_code}')
	}

	// Parse response
	rooms_response := json.decode(ListRoomsResponse, response.body) or {
		return error('Failed to parse response: ${err}')
	}

	return rooms_response
}
