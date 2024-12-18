module canva

import os

// Download a design from Canva using the design ID
pub fn (c CanvaClient) download(design_id string) !string {
	curl_cmd := "curl -X GET 'https://api.canva.com/v1/designs/${design_id}/download' -H 'Authorization: Bearer ${c.secret}' -H 'Content-Type: application/json'"

	result := os.execute(curl_cmd)
	if result.exit_code != 0 {
		return error('Failed to download design: ${result.output}')
	}

	return result.output
}
