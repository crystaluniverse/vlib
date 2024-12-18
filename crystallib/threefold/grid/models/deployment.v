module models

import crypto.md5
import json

pub struct SignatureRequest {
pub mut:
	// unique id as used in TFGrid DB
	twin_id u32
	// if put on required then this twin_id needs to sign
	required bool
	// signing weight
	weight int
}

// Challenge computes challenge for SignatureRequest
pub fn (request SignatureRequest) challenge() string {
	mut out := []string{}
	out << '${request.twin_id}'
	out << '${request.required}'
	out << '${request.weight}'

	return out.join('')
}

pub struct Signature {
pub mut:
	// unique id as used in TFGrid DB
	twin_id u32
	// signature (done with private key of the twin_id)
	signature      string
	signature_type string
}

pub struct SignatureRequirement {
pub mut:
	// the requests which can allow to get to required quorum
	requests []SignatureRequest
	// minimal weight which needs to be achieved to let this workload become valid
	weight_required int
	signatures      []Signature
	signature_style string
}

// Challenge computes challenge for SignatureRequest
pub fn (requirement SignatureRequirement) challenge() string {
	mut out := []string{}

	for request in requirement.requests {
		out << request.challenge()
	}

	out << '${requirement.weight_required}'
	out << '${requirement.signature_style}'
	return out.join('')
}

// deployment is given to each Zero-OS who needs to deploy something
// the zero-os'es will only take out what is relevant for them
// if signature not done on the main Deployment one, nothing will happen
@[heap]
pub struct Deployment {
pub mut:
	// increments for each new interation of this model
	// signature needs to be achieved when version goes up
	version u32 = 1
	// the twin who is responsible for this deployment
	twin_id u32
	// each deployment has unique id (in relation to originator)
	contract_id u64
	// when the full workload will stop working
	// default, 0 means no expiration
	expiration  i64
	metadata    string
	description string
	// list of all worklaods
	workloads []Workload

	signature_requirement SignatureRequirement
}

@[params]
pub struct DeploymentArgs {
pub:
	version               ?u32
	twin_id               u32
	contract_id           u64
	expiration            ?i64
	metadata              DeploymentData
	description           ?string
	workloads             []Workload
	signature_requirement SignatureRequirement
}

pub fn (deployment Deployment) challenge() string {
	// we need to scape `"` with `\"`char when sending the payload to be a valid json but when calculating the challenge we should remove `\` so we don't get invlaid signature
	metadata := deployment.metadata.replace('\\"', '"')
	mut out := []string{}
	out << '${deployment.version}'
	out << '${deployment.twin_id}'
	out << '${metadata}'
	out << '${deployment.description}'
	out << '${deployment.expiration}'
	for workload in deployment.workloads {
		out << workload.challenge()
	}
	out << deployment.signature_requirement.challenge()
	ret := out.join('')
	return ret
}

// ChallengeHash computes the hash of the challenge signed
// by the user. used for validation
pub fn (deployment Deployment) challenge_hash() []u8 {
	return md5.sum(deployment.challenge().bytes())
}

pub fn (mut d Deployment) add_signature(twin u32, signature string) {
	for mut sig in d.signature_requirement.signatures {
		if sig.twin_id == twin {
			sig.signature = signature
			return
		}
	}

	d.signature_requirement.signatures << Signature{
		twin_id:        twin
		signature:      signature
		signature_type: 'sr25519'
	}
}

pub fn (mut d Deployment) json_encode() string {
	mut encoded_workloads := []string{}
	for mut w in d.workloads {
		encoded_workloads << w.json_encode()
	}

	workloads := '[${encoded_workloads.join(',')}]'
	return '{"version":${d.version},"twin_id":${d.twin_id},"contract_id":${d.contract_id},"expiration":${d.expiration},"metadata":"${d.metadata}","description":"${d.description}","workloads":${workloads},"signature_requirement":${json.encode(d.signature_requirement)}}'
}

pub fn (dl Deployment) count_public_ips() u8 {
	mut count := u8(0)
	for wl in dl.workloads {
		if wl.type_ == workload_types.public_ip {
			count += 1
		}
	}
	return count
}

pub fn new_deployment(args DeploymentArgs) Deployment {
	return Deployment{
		version:               args.version or { 0 }
		twin_id:               args.twin_id
		contract_id:           args.contract_id
		expiration:            args.expiration or { 0 }
		metadata:              args.metadata.json_encode()
		description:           args.description or { '' }
		workloads:             args.workloads
		signature_requirement: args.signature_requirement
	}
}

pub struct DeploymentData {
pub:
	type_        string @[json: 'type']
	name         string
	project_name string @[json: 'projectName']
}

pub fn (data DeploymentData) json_encode() string {
	return "{\\\"type\\\":\\\"${data.type_}\\\",\\\"name\\\":\\\"${data.name}\\\",\\\"projectName\\\":\\\"${data.project_name}\\\"}"
}

pub fn (mut dl Deployment) add_metadata(type_ string, project_name string) {
	mut data := DeploymentData{
		type_:        type_
		name:         project_name
		project_name: '${type_}/${project_name}' // To be listed in the dashboard.
	}
	dl.metadata = data.json_encode()
}

pub fn (mut d Deployment) parse_metadata() !DeploymentData {
	return json.decode(DeploymentData, d.metadata)!
}
