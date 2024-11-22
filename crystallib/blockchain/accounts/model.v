module blockchain
import freeflowuniverse.crystallib.core.texttools

@[heap]
pub struct DigitalAssets {
pub mut:
    name string
    owners []Owner
    assettypes []AssetType
}

@[heap]
pub struct Owner {
pub mut:
    name        string
	accounts []Account
}

@[heap]
pub struct Account {
pub mut:
    name        string
    secret      string
    pubkey      string
    description string
    cat         string 
    owner 		string 
    assets      []Asset
	bctype 		BlockChainType
}

@[heap]
pub struct Asset {
pub mut:
	amount      int
	assettype 		AssetType
}

pub fn (self Asset) name() string {
	return self.assettype.name
}

pub struct AssetType {
pub mut:
    name        string
	issuer      string
	bctype 		BlockChainType
}

pub enum BlockChainType{
	stellar
	stellar_test

}


//////// ACCOUNT GETTERS

@[params]
pub struct AccountGetArgs{
pub mut:
    owner string
	name string
	bctype BlockChainType	
}

pub fn (mut self DigitalAssets) accounts_get(args_ AccountGetArgs) ![]&Account {

    mut accounts := []&Account{}
	mut args:=args_

	args.name = texttools.name_fix(args.name)
    args.owner = texttools.name_fix(args.owner)
    
    for mut owner in self.owners {
        if owner.name == args.owner || args.owner == "" {
            for mut account in owner.accounts {
                if account.name == args.name && account.bctype == args.bctype {
                    accounts<<&account 
                }
            }
        }
    }
    
    return accounts
}


pub fn (mut self DigitalAssets) account_get(args_ AccountGetArgs) !&Account {

    mut accounts := self.accounts_get(args_)!
    if accounts.len == 0 {
        return error('No account found with the given name:${args_.name} and blockchain type: ${args_.bctype}')
    } else if accounts.len  > 1 {
        return error('Multiple accounts found with the given name:${args_.name} and blockchain type: ${args_.bctype}')
    }
        
    return accounts[0]
}
