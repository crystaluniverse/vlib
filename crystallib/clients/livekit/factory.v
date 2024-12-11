
module livekit

pub fn new(client Client) Client {
	return Client{...client}
}