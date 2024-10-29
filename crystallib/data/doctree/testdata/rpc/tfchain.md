
# TFChain
TODO: intro

## Remote Procedure Calls

### Load

****Request****
```
{
    "jsonrpc": "2.0",
    "method": "tfchain.Load",
    "params": {
        "passphrase": string,
        "network": string
    },
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

### Transfer

****Request****
```
{
    "jsonrpc": "2.0",
    "method": "tfchain.Transfer",
    "params": {
        "destination": string,
        "memo": string,
        "amount": u64
    },
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

### Balance

****Request****
```
{
    "jsonrpc": "2.0",
    "method": "tfchain.Balance",
    "params": "<address>",
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": i64,
    "id": "<GUID>"
}
```

### GetTwin

****Request****
```
{
    "jsonrpc": "2.0",
    "method": "tfchain.TwinGet",
    "params": <id>,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_TWIN>,
    "id": "<GUID>"
}
```

### GetNode

****Request****
```
{
    "jsonrpc": "2.0",
    "method": "tfchain.NodeGet",
    "params": <id>,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_NODE>,
    "id": "<GUID>"
}
```

### GetFarm

****Request****
```
{
    "jsonrpc": "2.0",
    "method": "tfchain.FarmGet",
    "params": <id>,
    "id": "<GUID>"
}
```
**Response**
```
{
    "jsonrpc": "2.0",
    "result": <MODEL_FARM>,
    "id": "<GUID>"
}
```

## Models

### MODEL_TWIN
```
{
    "id": u32,
    "account": string,
    "relay": string,
    "entities": [MODEL_ENTITYPROOF],
    "pk": string
}
```

### MODEL_ENTITYPROOF
```
{
    "entityid": u32,
    "signature": string
}
```

### MODEL_NODE
```
{
    "id": u32,
    "farmid": u32,
    "twinid": u32,
    "resources": <MODEL_RESOURCES>,
    "location": <MODEL_LOCATION>,
    "public_config": {
        "ip": <MODEL_IP>,
        "ip6": <MODEL_IP>,
        "domain": string
    },
    "created": u64,
    "farmingpolicy": u32,
    "interfaces": [MODEL_INTERFACE],
    "certification": "string",
    "secureboot": bool,
    "virtualized": bool,
    "serial": string,
    "connectionprice": u32
}
```
### MODEL_RESOURCES
```
{
    "hru": u64,
    "sru": u64,
    "cru": u64,
    "mru": u64
}
```
### MODEL_LOCATION

```
{
    "city": string,
    "country": string,
    "latitude": string,
    "longitude": string
}
```

### MODEL_IP

```
{
    "ip": string,
    "gw": string
}
```
### MODEL_INTERFACE

```
{
    "name": string,
    "mac": string,
    "ips": [string]
}
```

### MODEL_FARM

```
{
    "id": u32,
    "name": string,
    "twinid": u32,
    "pricingpolicyid": u32,
    "certificationtype": string,
    "publicips": [MODEL_PUBLICIP],
    "dedicated": bool,
    "farmingpolicylimit": <MODEL_FARMINGPOLICYLIMIT>
}
```

### MODEL_PUBLICIP

```
{
    "ip": string,
    "gateway": string,
    "contractid": u64
}
```

### MODEL_FARMINGPOLICYLIMIT
```
{
    "farmingpolicyid": u32,
    "cu": u64,
    "su": u64,
    "end": u64,
    "nodecount": u32,
    "nodecertification": bool
}
```