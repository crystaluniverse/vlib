
# TFgrid
TFgrid is one of the clients that web3 proxy opens up. Below you can find the remote procedure calls it can handle. We use the json rpc 2.0 protocol. All possible json rpc request are shown below with the corresponding response that the web3 proxy will send back.

## Remote Procedure Calls
In this section you'll find the json rpc requests and responses of all the remote procedure calls. The fields params can contain text formated as <MODEL_*>. These represent json objects that are defined further down the document in section [Models](#models). 

### Login
This rpc is used to login. It requires you to pass your menmonic and the network you want to deploy on. 

****Request****
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.Load",
    "params": [
        "<menomonic>",
        "<network>"
    ],
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": "",
    "id": "<GUID>"
}
```

### Gateway Name Deploy
This rpc allows you to deploy a gateway name. It requires you to pass the information required for a gateway name. Upon success it will return you that same information extended with some extra useful data. 

****Request****
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.gateway.name.deploy",
    "params": [<MODEL_GATEWAYNAME>],
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_GATEWAYNAMERESULT>,
    "id": "<GUID>"
}
```

### GatewayNameDelete
This rpc allows you to delete a deployed gateway name. You should send the name in the params field. The operation succeeded if you receive a valid json rpc 2.0 result.

****Request****
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.GatewayNameDelete",
    "params": ["<name>"],
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": "",
    "id": "<GUID>"
}
```

### GatewayNameGet
You can always ask for information on a gateway name via the rpc shown below. Just set the name in the params field of the json rpc 2.0 request. The response will contain the requested information.

**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.GatewayNameGet",
    "params": "<name>",
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_GATEWAYNAMERESULT>,
    "id": "<GUID>"
}
```

### GatewayFQDNDeploy
If you wish for a fully qualified domain name you should use the rpc shown below. It requires the data shown in [this model](#model_gatewayfqdn) and returns that same data augmented with [some extra fields](#model_gatewayfqdnresult).

**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.GatewayFQDNDeploy",
    "params": <MODEL_GATEWAYFQDN>,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_GATEWAYFQDNRESULT>,
    "id": "<GUID>"
}
```

### GatewayFQDNDelete
You can delete your requested fully qualified domain name with the rpc shown below. Just fill in the name in the json rpc request. 

**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.GatewayFQDNDelete",
    "params": "<name>",
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": "",
    "id": "<GUID>"
}
```

### GatewayFQDNGet
Once created you can always retrieve the [data](#model_gatewayfqdnresult) related to your fully qualified domain name via the rpc method *tfgrid.GatewayFQDNget*. 

**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.GatewayFQDNGet",
    "params": "<name>",
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_GATEWAYFQDNRESULT>,
    "id": "<GUID>"
}
```

### K8sDeploy


**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.K8sDeploy",
    "params": <MODEL_K8SCLUSTER>,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_K8SCLUSTERRESULT>,
    "id": "<GUID>"
}
```

### K8sDelete
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.K8sDelete",
    "params": string,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": "",
    "id": "<GUID>"
}
```

### K8sGet
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.K8sGet",
    "params": string,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_K8SCLUSTERRESULT>,
    "id": "<GUID>"
}
```

### K8sGet
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.K8sAddnode",
    "params": {
        "name": string,
        "node": <MODEL_K8SNODE>
    },
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_K8SCLUSTERRESULT>,
    "id": "<GUID>"
}
```


### K8sRemoveNode
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.K8sRemovenode",
    "params": {
        "name": string,
        "nodename": string
    },
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_K8SCLUSTERRESULT>,
    "id": "<GUID>"
}
```

### MachinesDeploy
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.MachinesDeploy",
    "params": <MODEL_MACHINES>,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_MACHINESRESULT>,
    "id": "<GUID>"
}
```

### MachinesDelete
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.MachinesDelete",
    "params": string,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": "",
    "id": "<GUID>"
}
```

### MachinesGet
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.MachinesGet",
    "params": string,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_MACHINESRESULT>,
    "id": "<GUID>"
}
```

### MachineAdd
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.MachinesAdd",
    "params": {
        "project_name": string,
        "machine": <MODEL_MACHINE>
    },
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_MACHINESRESULT>,
    "id": "<GUID>"
}
```

### MachineRemove
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.MachinesRemove",
    "params": {
        "machine_name": string,
        "project_name": string
    },
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_MACHINESRESULT>,
    "id": "<GUID>"
}
```

### DeploymentDeploy
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.DeploymentCreate",
    "params": <MODEL_DEPLOYMENT>,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_DEPLOYMENTRESULT>,
    "id": "<GUID>"
}
```

### DeploymentUpdate
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.DeploymentUpdate",
    "params": <MODEL_DEPLOYMENT>,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_DEPLOYMENTRESULT>,
    "id": "<GUID>"
}
```

### DeploymentCancel
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.DeploymentCancel",
    "params": i64,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": "",
    "id": "<GUID>"
}
```

### DeploymentGet
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.DeploymentGet",
    "params": i64,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_DEPLOYMENT>,
    "id": "<GUID>"
}
```

### ZDBDeploy
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.ZdbDeploy",
    "params": <MODEL_ZDB>,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_ZDBRESULT>,
    "id": "<GUID>"
}
```

### ZDBDelete
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.ZdbDelete",
    "params": string,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": "",
    "id": "<GUID>"
}
```

### ZDBGet
**Request**
```
{
    "jsonrpc": "2.0",
    "method": "tfgrid.ZdbGet",
    "params": string,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_ZDBRESULT>,
    "id": "<GUID>"
}
```

## Models

### MODEL_CREDENTIALS
```
{
    "mnemonics": string,
    "network": string
}
```

### MODEL_GATEWAYNAME
```
{
    "nodeid": U32,
    "name": string,
    "backends": [string],
    "tlspassthrough": bool,
    "description": string
}
```

### MODEL_GATEWAYNAMERESULT
```
{
    "nodeid": U32,
    "name": string,
    "backends": [string],
    "tlspassthrough": bool,
    "description": string,
    "fqdn": string,
    "namecontractid": u64,
    "contractid": u64
}
```

### MODEL_GATEWAYFQDN
```
{
    "nodeid": U32,
    "backends": [string],
    "fqdn": string,
    "name": string,
    "tlspassthrough": bool,
    "description": string
}
```

### MODEL_GATEWAYFQDNRESULT
```
{
    "nodeid": U32,
    "backends": [string],
    "fqdn": string,
    "name": string,
    "tlspassthrough": bool,
    "description": string,
    "contractid": u64
}
```

### MODEL_K8SCLUSTER
```
{
    "name": string,
    "master": MODEL_K8SNODE,
    "workers": [MODEL_K8SNODE],
    "token": string,
    "ssh_key": string,
}
```
### MODEL_K8SCLUSTER_RESULT
```
{
    "name": string,
    "master": MODEL_K8SNODE,
    "workers": [MODEL_K8SNODE],
    "token": string,
    "ssh_key": string,
    "node_deployment_id": map[u32]u64
}
```
### MODEL_K8SNODE
```
{
    "name": string,
    "nodeid": string,
    "public_ip": bool,
    "public_ip6": bool,
    "planetary": bool,
    "flist": string,
    "cpu": u32,
    "memory": u32, //in MBs
    "disk_size": u32 // in GB, monted in /mydisk
}
```
### MODEL_K8SNODERESULT
```
{
    "name": string,
    "nodeid": string,
    "public_ip": bool,
    "public_ip6": bool,
    "planetary": bool,
    "flist": string,
    "cpu": u32,
    "memory": u32, //in MBs
    "disk_size": u32, // in GB, monted in /mydisk
    "computed_ip4": string,
    "computed_ip6": string,
    "wg_ip": string,
    "planetary_ip": string
}
```

### MODEL_DEPLOYMENT
```
{
    "version": int,
    "twin_id": u32,
    "contract_id": u64,
    "expiration": i64,
    "metadata": string,
    "description": string,
    "workloads": [MODEL_WORKLOAD],
    "signature_requirement": SignatureRequirement
}
```

### MODEL_ZDB
```
{
    "node_id": u32,
    "name": string,
    "password": string,
    "public": bool,
    "size": u32, // in GB
    "description": string,
    "mode": string
}
```

### MODEL_ZDBRESULT
```
{
    "node_id": u32,
    "name": string,
    "password": string,
    "public": bool,
    "size": u32, // in GB
    "description": string,
    "mode": string,
    "namespace": string,
    "port": u32,
    "ips": [string]
}
```