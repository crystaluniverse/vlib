module action

// ProcedureResponse struct representing the result of a procedure call
pub struct ProcedureResponse {
pub:
    result string    // Response data
    error  string    // Internal error message (if any)
}

// Parameters for processing a procedure call
@[params]
pub struct ProcessParams {
pub:
    timeout int // Timeout in seconds
}