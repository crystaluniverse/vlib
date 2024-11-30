module meet

import freeflowuniverse.crystallib.osal
import veb
import rand
import os
import json
import freeflowuniverse.crystallib.web.auth.jwt
import time

// Struct for ConnectionDetails
pub struct ConnectionDetails {
	server_url        string [json: 'serverUrl']
	room_name         string [json: 'roomName']
	participant_token string [json: 'participantToken']
	participant_name  string [json: 'participantName']
}

// GET endpoint to handle participant token generation
@['/connection-details'; get]
pub fn (app &App) participant_endpoint(mut ctx Context) veb.Result {
	// Extract query parameters
	room_name := ctx.query['roomName'] or {
		return ctx.request_error('Missing required query parameter: roomName')
	}
	participant_name := ctx.query['participantName'] or {
		return ctx.request_error('Missing required query parameter: participantName')
	}
	metadata := ctx.query['metadata'] or { '' }
	region := ctx.query['region'] or { '' }

	// Determine the LiveKit server URL based on region
	livekit_server_url := if region != '' {
		get_livekit_url(region) or {
			return ctx.server_error('Invalid region: $err')
		}
	} else {
		app.livekit_url
	}

	// Generate participant token
	participant_token := app.create_participant_token(participant_name, room_name, metadata) or {
		return ctx.server_error('Failed to create participant token: $err')
	}

	// Create connection details response
	connection_details := ConnectionDetails{
		server_url: livekit_server_url
		room_name: room_name
		participant_token: participant_token
		participant_name: participant_name
	}

	// Return JSON response
	return ctx.json(connection_details)
}

// Function to create a participant token
fn (app &App) create_participant_token(participant_name string, room_name string, metadata string) !string {
	// Generate a random string for the participant's identity
	identity := '${participant_name}__${rand.string(4)}'

	// Set up access token options
	options := AccessTokenOptions{
		identity: identity
		name: participant_name
		metadata: metadata
		ttl: 300 // Token expiration: 5 minutes
	}

	// Create a new access token using the client
	mut token := new_access_token(app.api_key, app.api_secret, options)!

	// Create a video grant and add it to the token
	video_grant := VideoGrant{
		room: room_name
		room_join: true
		can_publish: true
		can_publish_data: true
		can_subscribe: true
	}
	token.add_video_grant(video_grant)

	// Generate and return the JWT
	return token.to_jwt()
}

// Helper function to get LiveKit server URL based on the region
fn get_livekit_url(region string) !string {
	target_key := if region != '' { 'LIVEKIT_URL_${region}'.to_upper() } else { 'LIVEKIT_URL' }
	livekit_url := os.getenv(target_key)
	return livekit_url
}