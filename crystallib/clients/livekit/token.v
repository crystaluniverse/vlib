module livekit

import time
import rand
import crypto.hmac
import crypto.sha256
import encoding.base64
import json

// Define AccessTokenOptions struct
@[params]
pub struct AccessTokenOptions {
	pub mut:
		ttl      int | string // TTL in seconds or a time span (e.g., '2d', '5h')
		name     string // Display name for the participant
		identity string // Identity of the user
		metadata string // Custom metadata to be passed to participants
}

// Constructor for AccessToken
pub fn (client Client) new_access_token(options AccessTokenOptions) !AccessToken {
	ttl := if options.ttl is int { options.ttl } else { 21600 } // Default TTL of 6 hours (21600 seconds)

	return AccessToken{
		api_key: client.api_key
		api_secret: client.api_secret
		identity: options.identity
		ttl: ttl
		grants: ClaimGrants{
			exp: time.now().unix()+ttl
			iss: client.api_key
			sub: options.name
			name: options.name
		}
	}
}