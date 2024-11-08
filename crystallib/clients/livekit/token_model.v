module livekit

import time
import rand
import crypto.hmac
import crypto.sha256
import encoding.base64
import json

// Struct representing grants
pub struct ClaimGrants {
pub mut:
		video     VideoGrant
		iss string
		exp i64
		nbf int
		sub string
		name      string
}

// VideoGrant struct placeholder
pub struct VideoGrant {
pub mut:
		room       string
		room_join  bool @[json: 'roomJoin']
		room_list  bool @[json: 'roomList']
		can_publish bool @[json: 'canPublish']
		can_publish_data bool @[json: 'canPublishData']
		can_subscribe bool @[json: 'canSubscribe']
}

// SIPGrant struct placeholder
struct SIPGrant {}

// AccessToken class
pub struct AccessToken {
	mut:
		api_key    string
		api_secret string
		grants     ClaimGrants
		identity   string
		ttl        int | string
}

// Method to add a video grant to the token
pub fn (mut token AccessToken) add_video_grant(grant VideoGrant) {
	token.grants.video = grant
}

// Method to generate a JWT token
pub fn (token AccessToken) to_jwt() !string {
	// Create JWT payload
	payload := json.encode(token.grants)

	println('payload: ${payload}')

	// Create JWT header
	header := '{"alg":"HS256","typ":"JWT"}'

	// Encode header and payload in base64
	header_encoded := base64.url_encode_str(header)
	payload_encoded := base64.url_encode_str(payload)

	// Create the unsigned token
	unsigned_token := '${header_encoded}.${payload_encoded}'

	// Create the HMAC-SHA256 signature
	signature := hmac.new(token.api_secret.bytes(), unsigned_token.bytes(), sha256.sum, sha256.block_size)

	// Encode the signature in base64
	signature_encoded := base64.url_encode(signature)

	// Create the final JWT
	jwt := '${unsigned_token}.${signature_encoded}'
	return jwt
}