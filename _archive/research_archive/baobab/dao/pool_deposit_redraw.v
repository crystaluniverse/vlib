module dao

import time

struct FundingArgs {
	currency string
	account  &Account
	amount   f64
}

// get money from your treasury private wallet and send to the treasury pool wallet
// once money has been send to the treasury pool you can not retrieve it, there are rules on how money can be retrieved
//```args
// 	currency string
// 	account &Account
// 	amount f64
//```
// add money to the dao poolfor a user
pub fn (mut dao DAO) pool_deposit(args FundingArgs) !&LPWallet {
	mut r := dao.pools_wallet_get(args.account, args.currency, true)!

	r.wallet.modified = true
	r.wallet.amount += args.amount
	r.wallet.amount_funded += args.amount
	r.wallet.modtime = dao.time_current

	return r.wallet
}

// get money out of pool towards your treasury prviate wallet
//```args
// 	currency string
// 	account &Account
// 	amount f64
//```
// pub fn (mut dao DAO) pool_withdraw(args FundingArgs) !&LPWallet {
// }
