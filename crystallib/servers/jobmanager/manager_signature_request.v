module jobmanager

import freeflowuniverse.crystallib.data.ourtime

// Params for finding signature requests
pub struct SignatureRequestFindParams {
pub mut:
	id       ?u32
	job      ?u32
	pubkey   ?string
	verified ?bool
}

// Manager for SignatureRequest objects
pub struct SignatureRequestManager {
mut:
	requests map[u32]SignatureRequest
	last_id  u32
}

// Create a new signature request manager
pub fn new_signature_request_manager() SignatureRequestManager {
	return SignatureRequestManager{
		requests: map[u32]SignatureRequest{}
		last_id:  0
	}
}

// Set (create/update) a signature request
pub fn (mut m SignatureRequestManager) set(mut request SignatureRequest) !SignatureRequest {
	if request.id == 0 {
		// New request
		m.last_id++
		request.id = m.last_id
		request.date = ourtime.now()
	}
	m.requests[request.id] = request
	return request
}

// Get a signature request by ID
pub fn (m SignatureRequestManager) get(id u32) !SignatureRequest {
	if id in m.requests {
		return m.requests[id]
	}
	return error('SignatureRequest with ID ${id} not found')
}

// Delete a signature request by ID
pub fn (mut m SignatureRequestManager) delete(id u32) ! {
	if id in m.requests {
		m.requests.delete(id)
		return
	}
	return error('SignatureRequest with ID ${id} not found')
}

// Delete all signature requests
pub fn (mut m SignatureRequestManager) delete_all() {
	m.requests.clear()
	m.last_id = 0
}

// Find signature requests based on parameters
pub fn (m SignatureRequestManager) find(params SignatureRequestFindParams) []SignatureRequest {
	mut result := []SignatureRequest{}

	for _, request in m.requests {
		if !matches_signature_request_params(request, params) {
			continue
		}
		result << request
	}

	return result
}

// Helper function to check if a signature request matches the find parameters
fn matches_signature_request_params(request SignatureRequest, params SignatureRequestFindParams) bool {
	if id := params.id {
		if id != request.id {
			return false
		}
	}
	if job := params.job {
		if job != request.job {
			return false
		}
	}
	if pubkey := params.pubkey {
		if pubkey != request.pubkey {
			return false
		}
	}
	if verified := params.verified {
		if verified != request.verified {
			return false
		}
	}
	return true
}
