module dao

import time

// send money to your personal wallet on the DAO treasury
// this money you can freely been redraw
// from here you can bring the money to the DAO Pool but then certain rules are in place
//```args
// 	currency string
// 	account &Account
// 	amount f64
//```
pub fn (mut dao DAO) wallet_deposit(args FundingArgs) !&LPWallet {
	mut r := dao.pools_wallet_get(args.account, args.currency, false)!

	r.wallet.modified = true
	r.wallet.amount += args.amount
	r.wallet.amount_funded += args.amount
	r.wallet.modtime = dao.time_current

	// check if person has also usdc account, if not need to create
	if args.account.address !in lpusd.wallets_pool {
		dao.fund(currency: 'usdc', account: args.account, amount: 0, inpool: true)!
	}

	return &p
}

// withdraw money from your wallet and end back to your personal account where the money came from
// important for now we only support sending money back to blockchain account who put the money in
//```args
// 	currency string
// 	account &Account
// 	amount f64
//```
pub fn (mut dao DAO) wallet_withdraw(args FundingArgs) !&LPWallet {
	// TODO: this code is copy from above, needs to be all changed

	return &p
}

struct WalletArgs {
	currency string
	account  &Account
	ispool   bool
}

// get wallet information, is from your wallet on the DAO Treasory
// args
// - currency string
// - account &Account
pub fn (mut dao DAO) wallet_get(args WalletArgs) !&LPWallet {
	// TODO
}
