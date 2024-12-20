module rpc

// ProcedureCall struct representing a procedure invocation
pub struct ProcedureCall {
pub:
    method string    // Method name (derived from OpenAPI path)
    params string    // Parameters for the procedure
}

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