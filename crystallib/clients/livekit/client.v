module livekit

// App struct with `livekit.Client`, API keys, and other shared data
pub struct Client {
pub:
	url string @[required]
	api_key        string @[required]
	api_secret     string @[required]
}
