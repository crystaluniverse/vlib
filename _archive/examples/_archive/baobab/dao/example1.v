module main

import freeflowuniverse.crystallib.baobab.dao
import libsodium

fn simulate() ? {
	mut dao := dao.get('/tmp/dao')?

	dao.time_set('2022-07-05 10:10:04')?

	// need to define the basic price, in reality this can only be done by the council and needs consensus
	dao.pool_set(currency: 'tft', usdprice_buy: 0.05, usdprice_sell: 0.1)?

	// add public key
	// mut pk := libsodium.PrivateKey{
	// 	public_key: []u8{len: libsodium.public_key_size}
	// 	secret_key: []u8{len: libsodium.secret_key_size}
	// }
	// println(pk)

	mut kristof := dao.account_get('aabbccddeeff', 'kristof')?

	mut lp_tft := dao.pool_get('tft')?
	mut lp_usd := dao.pool_get('usdc')?

	dao.fund(currency: 'tft', account: kristof, amount: 99, inpool: true)?
	dao.fund(currency: 'usdc', account: kristof, amount: 1000, inpool: true)?

	// put private cash in, can always set & get back without any limits
	// private cash is needed otherwise transactions cannot happen
	dao.fund(currency: 'usdc', account: kristof, amount: 10000, inpool: false)?

	dao.time_add_seconds(1) // is in seconds

	mut timur := dao.account_get('aabbccddeedd', 'timur')?

	dao.fund(currency: 'usdc', account: timur, amount: 775, inpool: true)?

	// we always buy from usd account
	dao.buy(currency: 'tft', account: kristof, amount: 1000)? // this means kristof is buying 1000 tft, this needs to come from his personal account, if not there will fail

	println(dao)
}

fn main() {
	simulate() or { panic(err) }
}
