module model

pub struct PublicIP {
pub:
	id          string
	ip          string
	farm_id     string @[json: farmId]
	contract_id int    @[json: contractId]
	gateway     string
}

pub struct Farm {
pub:
	name               string
	farm_id            u64    @[json: farmId]
	twin_id            u64    @[json: twinId]
	pricing_policy_id  u64    @[json: pricingPolicyId]
	certification_type string @[json: certificationType]
	stellar_address    string @[json: stellarAddress]
	dedicated          bool
	public_ips         []PublicIP @[json: publicIps]
}
