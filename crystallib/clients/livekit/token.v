module livekit

import time
import rand
import crypto.hmac
import crypto.sha256
import encoding.base64
import json

// Client represents a LiveKit client with API credentials
// pub struct Client {
// pub mut:
// 	api_key    string // LiveKit API Key
// 	api_secret string // LiveKit API Secret
// }

// TTLValue represents either seconds as int or duration as string
pub type TTLValue = int | string

// ClaimGrants represents the JWT claims for LiveKit
pub struct ClaimGrants {
pub mut:
	exp  i64    // Expiration time
	iss  string // Issuer (API Key)
	sub  string // Subject (user ID)
	name string // User's display name
}

// AccessToken represents a LiveKit access token
pub struct AccessToken {
pub mut:
	api_key    string      // LiveKit API Key
	api_secret string      // LiveKit API Secret
	identity   string      // User identity
	ttl        int         // Time to live in seconds
	grants     ClaimGrants // JWT claims
}

// AccessTokenOptions defines parameters for token generation
pub struct AccessTokenOptions {
pub mut:
	ttl      TTLValue // TTL in seconds or a time span (e.g., '2d', '5h')
	name     string   // Display name for the participant
	identity string   // Identity of the user
	metadata string   // Custom metadata to be passed to participants
}

// new_access_token creates a new access token with the given options
pub fn (client Client) new_access_token(options AccessTokenOptions) !AccessToken {
	// Convert TTL to seconds
	ttl := match options.ttl {
		int { options.ttl }
		string { 21600 } // Default 6 hours if string format not handled
	}

	return AccessToken{
		api_key:    client.api_key
		api_secret: client.api_secret
		identity:   options.identity
		ttl:        ttl
		grants:     ClaimGrants{
			exp:  time.now().unix() + ttl
			iss:  client.api_key
			sub:  options.name
			name: options.name
		}
	}
}
