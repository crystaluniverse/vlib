module dao

import time

// asset = money stored in liqduitity pool, is owned by an account
// is like your private wallet on top of your treasury
@[heap]
pub struct LPWallet {
pub mut:
	account        &Account // pointer to account who owns position
	amount         f64
	amount_funded  f64 // this is how much was funded by the user, the usdvalue is higher because of rewards of being in the pool
	modtime        time.Time
	poolpercentage f64 // expressed in 0-100 as float
	modified       bool = true
}
