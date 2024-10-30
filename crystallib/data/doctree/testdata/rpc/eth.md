# Eth

TODO

## Remote Procedure Calls

In this section you'll find the json rpc requests and responses of all the remote procedure calls. The fields params can contain text formated as <MODEL_*>. These represent json objects that are defined further down the document in section [Models](#models).

### Load

****Request****

```
{
    "jsonrpc": "2.0",
    "method": "eth.Load",
    "params": {
        "url": string,
        "secret": string
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
    "method": "eth.Balance",
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

### Height

****Request****

```
{
    "jsonrpc": "2.0",
    "method": "eth.Height",
    "params": "",
    "id": "<GUID>"
}
```

**Response**

```
{
    "jsonrpc": "2.0",
    "result": u64,
    "id": "<GUID>"
}
```

### Transfer

Transaction id is returned

****Request****

```
{
    "jsonrpc": "2.0",
    "method": "eth.transfer",
    "params": {
        "destination": string,
        "amount": u64
    },
    "id": "<GUID>"
}
```

**Response**

```
{
    "jsonrpc": "2.0",
    "result": string,
    "id": "<GUID>"
}
```

### EthTftSpendingAllowance

****Request****

```json
{
    "jsonrpc": "2.0",
    "method": "eth.EthTftSpendingAllowance",
    "params": "",
    "id": "<GUID>"
}
```

**Response**

```json
{
    "jsonrpc": "2.0",
    "result": string,
    "id": "<GUID>"
}
```
