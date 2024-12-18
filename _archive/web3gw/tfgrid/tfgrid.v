module tfgrid

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }

// TFGridClient is a client containing an RpcWsClient instance, and implements all tfgrid functionality
@[openrpc: exclude]
@[noinit]
pub struct TFGridClient {
mut:
	client  &RpcWsClient
	timeout int
}

@[openrpc: exclude]
pub fn new(mut client RpcWsClient) TFGridClient {
	return TFGridClient{
		client:  &client
		timeout: 500000
	}
}

// Loads the provided mnemonic and connects to the provided network
pub fn (mut t TFGridClient) load(args Load) ! {
	_ := t.client.send_json_rpc[[]Load, string]('tfgrid.Load', [args], t.timeout)!
}

// Deploys a single VM with the configuration defined by DeployVM
pub fn (mut t TFGridClient) deploy_vm(args DeployVM) !VMDeployment {
	return t.client.send_json_rpc[[]DeployVM, VMDeployment]('tfgrid.DeployVM', [args],
		t.timeout)!
}

// Retrieves information about the deployed VM with the provided name
pub fn (mut t TFGridClient) get_vm_deployment(name string) !VMDeployment {
	return t.client.send_json_rpc[[]string, VMDeployment]('tfgrid.GetVMDeployment', [
		name,
	], t.timeout)!
}

// Cancels the deployment of the VM with the provided name
pub fn (mut t TFGridClient) cancel_vm_deployment(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.CancelVMDeployment', [
		name,
	], t.timeout)!
}

// Deploys the vms defined in the arguments and connects them to the same network which is also configured in the arguments
pub fn (mut t TFGridClient) deploy_network(args NetworkDeployment) !NetworkDeployment {
	return t.client.send_json_rpc[[]NetworkDeployment, NetworkDeployment]('tfgrid.DeployNetwork',
		[args], t.timeout)!
}

// Retrieves information about the network deployment (deployed vms, network details, etc)
pub fn (mut t TFGridClient) get_network_deployment(name string) !NetworkDeployment {
	return t.client.send_json_rpc[[]string, NetworkDeployment]('tfgrid.GetNetworkDeployment',
		[name], t.timeout)!
}

// Cancels the network deployment (cancels all the vms that are part of that network)
pub fn (mut t TFGridClient) cancel_network_deployment(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.CancelNetworkDeployment', [
		name,
	], t.timeout)!
}

// Deploys and add the VM described in the arguments to the specified network
pub fn (mut t TFGridClient) add_vm_to_network_deployment(args AddVMToNetworkDeployment) !NetworkDeployment {
	return t.client.send_json_rpc[[]AddVMToNetworkDeployment, NetworkDeployment]('tfgrid.AddVMToNetworkDeployment',
		[args], t.timeout)!
}

// Cancels the deployment of the VM with the name defined in the arguments and that is part of the provided network
pub fn (mut t TFGridClient) remove_vm_from_network_deployment(args RemoveVMFromNetworkDeployment) !NetworkDeployment {
	return t.client.send_json_rpc[[]RemoveVMFromNetworkDeployment, NetworkDeployment]('tfgrid.RemoveVMFromNetworkDeployment',
		[args], t.timeout)!
}

// Deploys the K8S cluster defined by the arguments
pub fn (mut t TFGridClient) deploy_k8s_cluster(args K8sCluster) !K8sCluster {
	return t.client.send_json_rpc[[]K8sCluster, K8sCluster]('tfgrid.DeployK8sCluster',
		[args], t.timeout)!
}

// Retrieves information about the K8S cluster with the name that is provided in the arguments
pub fn (mut t TFGridClient) get_k8s_cluster(name string) !K8sCluster {
	return t.client.send_json_rpc[[]string, K8sCluster]('tfgrid.GetK8sCluster', [
		name,
	], t.timeout)!
}

// Cancles the K8S cluster that is defined in the arguments
pub fn (mut t TFGridClient) cancel_k8s_cluster(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.CancelK8SCluster', [
		name,
	], t.timeout)!
}

// Adds a worker (deploys a new VM) to the provided K8S cluster and returns the configuration after the addition
pub fn (mut t TFGridClient) add_worker_to_k8s_cluster(args AddWorkerToK8sCluster) !K8sCluster {
	return t.client.send_json_rpc[[]AddWorkerToK8sCluster, K8sCluster]('tfgrid.AddWorkerToK8sCluster',
		[
		args,
	], t.timeout)!
}

// Removes the worker (the deployed vm) from the K8S cluster and returns the configuration after the removal
pub fn (mut t TFGridClient) remove_worker_from_k8s_cluster(args RemoveWorkerFromK8sCluster) !K8sCluster {
	return t.client.send_json_rpc[[]RemoveWorkerFromK8sCluster, K8sCluster]('tfgrid.RemoveWorkerFromK8sCluster',
		[
		args,
	], t.timeout)!
}

// Deploys a 0-DB on the requested node and returns some additional information about the 0-DB
pub fn (mut t TFGridClient) deploy_zdb(args ZDBDeployment) !ZDBDeployment {
	return t.client.send_json_rpc[[]ZDBDeployment, ZDBDeployment]('tfgrid.DeployZDB',
		[
		args,
	], t.timeout)!
}

// Retrieves information about the deployed 0-DB
pub fn (mut t TFGridClient) get_zdb_deployment(name string) !ZDBDeployment {
	return t.client.send_json_rpc[[]string, ZDBDeployment]('tfgrid.GetZDBDeployment',
		[
		name,
	], t.timeout)!
}

// Cancels the deployment of the 0-DB that has the name that is specified in the arguments
pub fn (mut t TFGridClient) cancel_zdb_deployment(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.CancelZDBDeployment', [
		name,
	], t.timeout)!
}

// Deploys a gateway name given the name, the id of the node and the backends where the gateway should point to
pub fn (mut t TFGridClient) deploy_gateway_name(args GatewayName) !GatewayName {
	return t.client.send_json_rpc[[]GatewayName, GatewayName]('tfgrid.GatewayNameDeploy',
		[
		args,
	], t.timeout)!
}

// Retrieves information about the gateway name (backends, node, etc)
pub fn (mut t TFGridClient) get_gateway_name(name string) !GatewayName {
	return t.client.send_json_rpc[[]string, GatewayName]('tfgrid.GatewayNameGet', [
		name,
	], t.timeout)!
}

// Cancels the gateway name
pub fn (mut t TFGridClient) cancel_gateway_name(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.GatewayNameDelete', [
		name,
	], t.timeout)!
}

// Adds a fully qualified domain name to the specified node and returns some computed information
pub fn (mut t TFGridClient) deploy_gateway_fqdn(args GatewayFQDN) !GatewayFQDN {
	return t.client.send_json_rpc[[]GatewayFQDN, GatewayFQDN]('tfgrid.GatewayFQDNDeploy',
		[
		args,
	], t.timeout)!
}

// Retrieves information about the fully qualified domain name
pub fn (mut t TFGridClient) get_gateway_fqdn(name string) !GatewayFQDN {
	return t.client.send_json_rpc[[]string, GatewayFQDN]('tfgrid.GatewayFQDNGet', [
		name,
	], t.timeout)!
}

// Cancels the fully qualified domain name specified in the arguments
pub fn (mut t TFGridClient) cancel_gateway_fqdn(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.GatewayFQDNDelete', [
		name,
	], t.timeout)!
}

// Returns the nodes that match the provided filters, the result is returned in pages of a specific size (defined by the arguments)
pub fn (mut t TFGridClient) find_nodes(args FindNodes) !NodesResult {
	return t.client.send_json_rpc[[]FindNodes, NodesResult]('tfgrid.FindNodes', [
		args,
	], t.timeout)!
}

// Returns the farms that match the provided filters, the result is returned in pages of a specific size (defined by the arguments)
pub fn (mut t TFGridClient) find_farms(args FindFarms) !FarmsResult {
	return t.client.send_json_rpc[[]FindFarms, FarmsResult]('tfgrid.FindFarms', [
		args,
	], t.timeout)!
}

// Returns the contracts that match the provided filters, the result is returned in pages of a specific size (defined by the arguments)
pub fn (mut t TFGridClient) find_contracts(args FindContracts) !ContractsResult {
	return t.client.send_json_rpc[[]FindContracts, ContractsResult]('tfgrid.FindContracts',
		[
		args,
	], t.timeout)!
}

// Returns the twins that match the provided filters, the result is returned in pages of a specific size (defined by the arguments)
pub fn (mut t TFGridClient) find_twins(args FindTwins) !TwinsResult {
	return t.client.send_json_rpc[[]FindTwins, TwinsResult]('tfgrid.FindTwins', [
		args,
	], t.timeout)!
}

// Returns global statistics on the threefold grid (amount of nodes, amount of farms, etc)
pub fn (mut t TFGridClient) statistics(args GetStatistics) !Statistics {
	return t.client.send_json_rpc[[]GetStatistics, Statistics]('tfgrid.Statistics', [
		args,
	], t.timeout)!
}

// Deploys a VM with discourse on it and returns additional information that might be relevant to access the VM
pub fn (mut t TFGridClient) deploy_discourse(args DeployDiscourse) !DiscourseDeployment {
	return t.client.send_json_rpc[[]DeployDiscourse, DiscourseDeployment]('tfgrid.DeployDiscourse',
		[
		args,
	], t.timeout)!
}

// Retrieves information about the deployed VM
pub fn (mut t TFGridClient) get_discourse_deployment(name string) !DiscourseDeployment {
	return t.client.send_json_rpc[[]string, DiscourseDeployment]('tfgrid.GetDiscourseDeployment',
		[
		name,
	], t.timeout)!
}

// Cancels the deployment
pub fn (mut t TFGridClient) cancel_discourse_deployment(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.CancelDiscourceDeployment',
		[
		name,
	], t.timeout)!
}

// Deploys a VM with funkwhale on it and returns additional information that might be relevant to access the VM
pub fn (mut t TFGridClient) deploy_funkwhale(args DeployFunkwhale) !FunkwhaleDeployment {
	return t.client.send_json_rpc[[]DeployFunkwhale, FunkwhaleDeployment]('tfgrid.DeployFunkwhale',
		[
		args,
	], t.timeout)!
}

// Retrieves information about the deployed VM
pub fn (mut t TFGridClient) get_funkwhale_deployment(name string) !FunkwhaleDeployment {
	return t.client.send_json_rpc[[]string, FunkwhaleDeployment]('tfgrid.GetFunkwhaleDeployment',
		[
		name,
	], t.timeout)!
}

// Cancels the deployment
pub fn (mut t TFGridClient) cancel_funkwhale_deployment(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.CancelFunkwhaleDeployment',
		[
		name,
	], t.timeout)!
}

// Deploys a VM with peertube on it and returns additional information that might be relevant to access the VM
pub fn (mut t TFGridClient) deploy_peertube(args DeployPeertube) !PeertubeDeployment {
	return t.client.send_json_rpc[[]DeployPeertube, PeertubeDeployment]('tfgrid.DeployPeertube',
		[
		args,
	], t.timeout)!
}

// Retrieves information about the deployed VM
pub fn (mut t TFGridClient) get_peertube_deployment(name string) !PeertubeDeployment {
	return t.client.send_json_rpc[[]string, PeertubeDeployment]('tfgrid.GetPeertubeDeployment',
		[
		name,
	], t.timeout)!
}

// Cancels the deployment
pub fn (mut t TFGridClient) cancel_peertube_deployment(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.CancelPeertubeDeployment', [
		name,
	], t.timeout)!
}

// Deploys a VM with presearch on it and returns additional information that might be relevant to access the VM
pub fn (mut t TFGridClient) deploy_presearch(args DeployPresearch) !PresearchDeployment {
	return t.client.send_json_rpc[[]DeployPresearch, PresearchDeployment]('tfgrid.DeployPresearch',
		[
		args,
	], t.timeout)!
}

// Retrieves information about the deployed VM
pub fn (mut t TFGridClient) get_presearch_deployment(name string) !PresearchDeployment {
	return t.client.send_json_rpc[[]string, PresearchDeployment]('tfgrid.GetPresearchDeployment',
		[
		name,
	], t.timeout)!
}

// Cancels the deployment
pub fn (mut t TFGridClient) cancel_presearch_deployment(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.CancelPresearchDeployment',
		[
		name,
	], t.timeout)!
}

// Deploys a VM with taiga on it and returns additional information that might be relevant to access the VM
pub fn (mut t TFGridClient) deploy_taiga(args DeployTaiga) !TaigaDeployment {
	return t.client.send_json_rpc[[]DeployTaiga, TaigaDeployment]('tfgrid.DeployTaiga',
		[
		args,
	], t.timeout)!
}

// Retrieves information about the deployed VM
pub fn (mut t TFGridClient) get_taiga_deployment(name string) !TaigaDeployment {
	return t.client.send_json_rpc[[]string, TaigaDeployment]('tfgrid.GetTaigaDeployment',
		[
		name,
	], t.timeout)!
}

// Cancels the deployment
pub fn (mut t TFGridClient) cancel_taiga_deployment(name string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfgrid.CancelTaigaDeployment', [
		name,
	], t.timeout)!
}
