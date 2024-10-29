
# Stellar

## Creating an account

Json RPC 2.0 request:

- network: the network you want to create the account on (public or testnet)


```json
{
    "jsonrpc":"2.0",
    "method":"stellar.CreateAccount",
    "params":[
        "public"
    ],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response:

- seed: the seed of the account that was generated

```json
{
    "jsonrpc":"2.0",
    "result":"seed_will_be_here",
    "id":"id_send_in_request"
}
```

## Loading your key

Json RPC 2.0 request:

- network: the network you want to connect to (public or testnet)
- secret: the secret of your stellar account

```json
{
    "jsonrpc":"2.0",
    "method":"stellar.Load",
    "params":[{
        "network":"public",
        "secret":"SA33FBB67CPIMHWTZYVR489Q6UKHFUPLKTLPG9BKAVG89I2J3SZNMW21"
    }],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response will be empty:

```json
{
    "jsonrpc":"2.0",
    "id":"id_send_in_request"
}
```

## Asking your public address

Json RPC 2.0 request (no parameters):

```json
{
    "jsonrpc":"2.0",
    "method":"stellar.Address",
    "params":[],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response:

- address: the public address of the loaded account

```json
{
    "jsonrpc":"2.0",
    "result":"public_address_will_be_here",
    "id":"id_send_in_request"
}
```

## Transfer tokens from one account to another

Json RPC 2.0 request:

- amount: the amount of tft to transfer (string)
- destination: the public address that should receive the tokens
- memo: the memo to add to the transaction

```json
{
    "jsonrpc":"2.0",
    "method":"stellar.Transfer",
    "params":[{
        "amount": "1520.0",
        "destination": "some_public_stellar_address",
        "memo": "your_memo_comes_here"
    }],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response:

- hash: the hash of the transaction that was executed

```json
{
    "jsonrpc":"2.0",
    "result":"hash_will_be_here",
    "id":"id_send_in_request"
}
```

## Swap tokens from one asset to the other

Json RPC 2.0 request:

- amount: the amount of tokens to swap (string)
- source_asset: the source asset to swap (should be tft or xlm)
- destination_asset: the asset to swap to (should be tft or xlm)

```json
{
    "jsonrpc":"2.0",
    "method":"stellar.Swap",
    "params":[{
        "amount": "5.0",
        "source_asset": "tft",
        "destination_asset": "xlm"
    }],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response:

- hash: the hash of the transaction that was executed

```json
{
    "jsonrpc":"2.0",
    "result":"hash_will_be_here",
    "id":"id_send_in_request"
}
```

## Get the balance of an account

Json RPC 2.0 request:

- address: the public address of an account to get the balance from (leave empty for your own account)

```json
{
    "jsonrpc":"2.0",
    "method":"stellar.Balance",
    "params":[
        "you_can_pass_public_address_here"
    ],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response:

- balance: the balance of the account (string)

```json
{
    "jsonrpc":"2.0",
    "result":"balance_will_be_here",
    "id":"id_send_in_request"
}
```

## Bridge stellar tft to ethereum

Json RPC 2.0 request:

- amount: the amount of tft to bridge (string)
- destination: the ethereum public address that should receive the tokens

```json
{
    "jsonrpc":"2.0",
    "method":"stellar.BridgeToEth",
    "params":[{
        "amount": "298.0",
        "destination": "eth_public_address_here"
    ],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response:

- hash: the hash of the transaction that was executed

```json
{
    "jsonrpc":"2.0",
    "result":"hash_will_be_here",
    "id":"id_send_in_request"
}
```

## Bridge stellar tft to tfchain

Json RPC 2.0 request:

- amount: the amount of tft on stellar to bridge to tfchain
- twin_id: the twin id that should receive the tokens

```json
{
    "jsonrpc":"2.0",
    "method":"stellar.BridgeToTfchain",
    "params":[{
        "amount": "21.0",
        "twin_id": 122
    ],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response:

- hash: the hash of the transaction that was executed

```json
{
    "jsonrpc":"2.0",
    "result":"hash_will_be_here",
    "id":"id_send_in_request"
}
```

## Waiting for a transaction on the Ethereum bridge

Json RPC 2.0 request:

- memo: the memo to look for in the transactions

```json
{
    "jsonrpc":"2.0",
    "method":"stellar.AwaitTransactionOnEthBridge",
    "params":[
        "provide_the_memo_here"
    ],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response: empty result

```json
{
    "jsonrpc":"2.0",
    "id":"id_send_in_request"
}
```

## Listing transactions

Json RPC 2.0 request:

- account: a public stellar address to get the transactions for (leave empty for your own account)
- limit: how many transactions you want to get (default 10)
- include_failed: include the failed transactions in the result (default is false)
- cursor: where to start listing the transactions from (default is the top)
- ascending: whether to sort the transactions in ascending order (default is false, so in descending order)

```json
{
    "jsonrpc":"2.0",
    "method":"stellar.Transactions",
    "params":[{
        "account": "some_account_here_or_leave_empty",
        "limit": 12,
        "include_failed": false,
        "cursor": "leave_empty_for_top",
        "ascending": false
    ],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response:

- a list of transactions (see [here](https://github.com/stellar/go/blob/01c7aa30745a56d7ffcc75bb8ededd38ba582a58/protocols/horizon/main.go#L484) for the definition of a transaction)

```json
{
    "jsonrpc":"2.0",
    "result":[
        {
            "id": "some_id",
            // many more attributes
        }
    ],
    "id":"id_send_in_request"
}
```

## Showing the data related to an account

Json RPC 2.0 request:

- address: the stellar public address to get the account data for (leave empty for your own account)

```json
{
    "jsonrpc":"2.0",
    "method":"stellar.AccountData",
    "params":[
        "account_or_leave_empty_for_your_account"
    ],
    "id":"a_unique_id_here"
}
```

Json RPC 2.0 response:

- account data (see [here](https://github.com/stellar/go/blob/01c7aa30745a56d7ffcc75bb8ededd38ba582a58/protocols/horizon/main.go#L33) for the definition of account data)

```json
{
    "jsonrpc":"2.0",
    "result": {
        "id": "some_id",
        // many more attributes
    },
    "id":"id_send_in_request"
}
```
