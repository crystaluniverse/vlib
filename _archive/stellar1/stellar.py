from stellar_sdk import Server
import json

# Set the Stellar network (use "https://horizon-testnet.stellar.org" for the testnet)
server = Server(horizon_url="https://horizon.stellar.org")

# Your Stellar account address
account_address = "YourAccountAddressHere"

class Position:
    def __init__(self, balance, asset_type):
        self.balance = balance
        self.asset_type = asset_type

    def to_dict(self):
        return {
            "balance": self.balance,
            "asset_type": self.asset_type
        }

class Account:
    def __init__(self, account_id):
        self.account_id = account_id
        self.positions = []

    def add_position(self, position):
        self.positions.append(position)

    def to_dict(self):
        return {
            "account_id": self.account_id,
            "positions": [position.to_dict() for position in self.positions]
        }

def get_account_balance(account_id):
    account_details = server.accounts().account_id(account_id).call()
    account = Account(account_id=account_id)

    for balance in account_details['balances']:
        asset_type = 'XLM' if balance['asset_type'] == 'native' else balance['asset_type']
        position = Position(balance=balance['balance'], asset_type=asset_type)
        account.add_position(position)
    
    return account.to_dict()


if __name__ == "__main__":

    account_data = get_account_balance(account_address)
    json.dumps(account_data, indent=4) #to catch error before we do result

    # Print the JSON string
    print("==RESULT==")
    print(json.dumps(account_data, indent=4))
