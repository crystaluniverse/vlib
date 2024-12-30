module action

// Error struct for error handling
pub struct ActionError {
    reason ErrorReason
}

// Enum for different error reasons
pub enum ErrorReason {
    timeout
    serialization_failed
    deserialization_failed
	enqueue_failed
}

pub fn (err ActionError) code() int {
    return match err.reason {
        .timeout { 408 }                    // HTTP 408 Request Timeout
        .serialization_failed { 500 }       // HTTP 500 Internal Server Error
        .deserialization_failed { 500 }     // HTTP 500 Internal Server Error
        .enqueue_failed { 503 }             // HTTP 503 Service Unavailable
    }
}

pub fn (err ActionError) msg() string {
    explanation := match err.reason {
        .timeout { 'The procedure call timed out.' }
        .serialization_failed { 'Failed to serialize the procedure call.' }
        .deserialization_failed { 'Failed to deserialize the procedure response.' }
        .enqueue_failed { 'Failed to enqueue the procedure response.' }
    }
    return 'Procedure failed: $explanation'
}
