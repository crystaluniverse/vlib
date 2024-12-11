module meet

import time
import rand
import crypto.hmac
import crypto.sha256
import encoding.base64
import json

// Define AccessTokenOptions struct
pub struct AccessTokenOptions {
	pub mut:
		ttl      int | string // TTL in seconds or a time span (e.g., '2d', '5h')
		name     string // Display name for the participant
		identity string // Identity of the user
		metadata string // Custom metadata to be passed to participants
}

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

// Constructor for AccessToken
pub fn new_access_token(api_key string, api_secret string, options AccessTokenOptions) !AccessToken {
	if api_key == '' || api_secret == '' {
		return error('API key and API secret must be set')
	}

	ttl := if options.ttl is int { options.ttl } else { 21600 } // Default TTL of 6 hours (21600 seconds)

	return AccessToken{
		api_key: api_key
		api_secret: api_secret
		identity: options.identity
		ttl: ttl
		grants: ClaimGrants{
			exp: time.now().unix()+ttl
			iss: api_key
			sub: options.name
			name: options.name
		}
	}
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

// TokenVerifier class
pub struct TokenVerifier {
	api_key    string
	api_secret string
}

// Constructor for TokenVerifier
pub fn new_token_verifier(api_key string, api_secret string) !TokenVerifier {
	if api_key == '' || api_secret == '' {
		return error('API key and API secret must be set')
	}
	return TokenVerifier{
		api_key: api_key
		api_secret: api_secret
	}
}

// Method to verify the JWT token
pub fn (verifier TokenVerifier) verify(token string) !ClaimGrants {
	// Split the token into parts
	parts := token.split('.')
	if parts.len != 3 {
		return error('Invalid token')
	}

	// Decode header, payload, and signature
	payload_encoded := parts[1]
	signature_encoded := parts[2]

	// Recompute the HMAC-SHA256 signature
	unsigned_token := '${parts[0]}.${parts[1]}'
	expected_signature := hmac.new(verifier.api_secret.bytes(), unsigned_token.bytes(), sha256.sum, sha256.block_size)
	expected_signature_encoded := base64.url_encode(expected_signature)

	// Verify the signature
	if signature_encoded != expected_signature_encoded {
		return error('Invalid token signature')
	}

	// Decode the payload
	payload_json := base64.url_decode_str(payload_encoded)

	// Parse and return the claims as ClaimGrants
	return json.decode(ClaimGrants, payload_json)
}