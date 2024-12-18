module tokens

import json
import freeflowuniverse.crystallib.httpcache
import freeflowuniverse.crystallib.ui.console

//
// Raw JSON struct
//
struct Raw_Wallet {
	address     string
	description string
	liquid      bool
	amount      string
}

struct Raw_FoundationAccountInfo {
	category string
	wallets  []Raw_Wallet
}

struct Raw_StatsTFT {
	total_tokens                     string
	total_accounts                   string
	total_locked_tokens              string
	total_vested_tokens              string
	total_liquid_foundation_tokens   string
	total_illiquid_foundation_tokens string
	total_liquid_tokens              string
	foundation_accounts_info         []Raw_FoundationAccountInfo
	locked_tokens_info               []string
}

struct Raw_Balance {
	amount string
	asset  string
}

struct Raw_Account {
	address          string
	balances         []Raw_Balance
	vesting_accounts []Raw_VestingAccount
	locked_amounts   []Raw_LockedAmount
}

struct Raw_VestingAccount {
	address       string
	vestingscheme string
	balances      []Raw_Balance
}

struct Raw_LockedAmount {
	address      string
	locked_until string
	balances     []Raw_Balance
}

struct Raw_StellarBalance {
	asset   string
	balance string
}

struct Raw_StellarHistory {
	ts       int
	payments int
	trades   int
	balances []Raw_StellarBalance
}

struct Raw_StellarAccount {
	account string
	history []Raw_StellarHistory
}

//
// Improved struct
//
pub struct Wallet {
pub mut:
	address     string
	description string
	liquid      bool
	amount      f64
}

pub struct FoundationAccountInfo {
pub mut:
	category string
	wallets  []Wallet
}

struct LockedTokensInfo {
pub mut:
	amount f64
	until  string
}

struct StatsTFT {
pub mut:
	total_tokens                     f64
	total_accounts                   f64
	total_locked_tokens              f64
	total_vested_tokens              f64
	total_liquid_foundation_tokens   f64
	total_illiquid_foundation_tokens f64
	total_liquid_tokens              f64
	foundation_accounts_info         []FoundationAccountInfo
	locked_tokens_info               []LockedTokensInfo
}

struct Balance {
pub:
	amount f64
	asset  string
}

struct Account {
pub mut:
	address          string
	balances         []Balance
	vesting_accounts []VestingAccount
	locked_amounts   []LockedAmount
}

struct VestingAccount {
pub mut:
	address       string
	vestingscheme string
	balances      []Balance
}

struct LockedAmount {
pub mut:
	address      string
	locked_until string
	balances     []Balance
}

struct Group {
pub mut:
	name         string
	distribution f32 // in percent from 0..1
	farmed       f64 // in tokens
	done         f64
	amount       f64
	remain       f64
}

//
// Workflow
//
fn account_url(account string) string {
	return 'https://statsdata.threefoldtoken.com/stellar_stats/api/account/' + account
}

fn parsef(f string) f64 {
	x := f.replace(',', '')
	return x.f64()
}

fn parse(tft Raw_StatsTFT, tfta Raw_StatsTFT, stellar Raw_StellarAccount) StatsTFT {
	mut final := StatsTFT{}

	final.total_tokens = parsef(tft.total_tokens) + parsef(tfta.total_tokens)
	final.total_accounts = parsef(tft.total_accounts) + parsef(tfta.total_accounts)
	final.total_locked_tokens = parsef(tft.total_locked_tokens) + parsef(tfta.total_locked_tokens)
	final.total_vested_tokens = parsef(tft.total_vested_tokens) + parsef(tfta.total_vested_tokens)
	final.total_liquid_foundation_tokens = parsef(tft.total_liquid_foundation_tokens) +
		parsef(tfta.total_liquid_foundation_tokens)
	final.total_illiquid_foundation_tokens = parsef(tft.total_illiquid_foundation_tokens) +
		parsef(tfta.total_illiquid_foundation_tokens)
	final.total_liquid_tokens = parsef(tft.total_liquid_tokens) + parsef(tfta.total_liquid_tokens)

	mut info := map[string]map[string]Wallet{}
	src := [tft, tfta]

	//
	// FoundationAccountInfo
	//
	for source in src {
		for entry in source.foundation_accounts_info {
			for wal in entry.wallets {
				mut found := info[entry.category][wal.address]

				found.address = wal.address
				found.description = wal.description
				found.liquid = wal.liquid
				found.amount += parsef(wal.amount)

				info[entry.category][wal.address] = found
			}
		}
	}

	for cat, val in info {
		mut accountinfo := FoundationAccountInfo{
			category: cat
		}

		for _, wal in val {
			accountinfo.wallets << wal
		}

		final.foundation_accounts_info << accountinfo
	}

	//
	// LockedTokensInfo
	//
	for source in src {
		for locked in source.locked_tokens_info {
			x := locked.fields()

			final.locked_tokens_info << LockedTokensInfo{
				amount: parsef(x[0])
				until:  x[3] + ' ' + x[4]
			}
		}
	}

	return final
}

pub fn parse_special(s StatsTFT) map[string]Group {
	// fixed 4 billion tokens
	// master_total_tokens := f64(4000000000)
	total_tokens := s.total_tokens

	// mut liquidity := tokens.FoundationAccountInfo{}
	mut contribution := FoundationAccountInfo{}
	mut council := FoundationAccountInfo{}

	for info in s.foundation_accounts_info {
		if info.category == 'threefold contribution wallets' {
			contribution = info
		}

		/*
		if info.category == "liquidity wallets" {
			liquidity = info
		}
		*/

		if info.category == 'wisdom council wallets' {
			council = info
		}
	}

	// console.print_debug(liquidity)

	mut group := map[string]Group{}

	// Farming rewards after April 19 2018 (***)
	group['farming-rewards-2018'] = Group{
		name:         'Farming rewards after April 19 2018'
		distribution: 0.75
		done:         s.total_tokens - 695000000 // Genesis pool
	}

	mut grant_amount := f64(0)

	for wallet in contribution.wallets {
		if wallet.description == 'TF Grants Wallet' {
			grant_amount += f64(wallet.amount)
		}
	}

	for wallet in council.wallets {
		if wallet.description == 'TF Grants Wisdom' {
			grant_amount += f64(wallet.amount)
		}
	}

	// Ecosystem Grants  (*)
	group['ecosystem-grants'] = Group{
		name:         'Ecosystem Grants'
		distribution: 0.03
		done:         grant_amount
	}

	// Promotion & Marketing Effort
	group['promotion-marketing'] = Group{
		name:         'Promotion & Marketing Effort '
		distribution: 0.05
		done:         100000000 // estimation
	}

	mut liquidity_amount := i64(0)

	for info in s.foundation_accounts_info {
		for wallet in info.wallets {
			if wallet.liquid == true {
				liquidity_amount += i64(wallet.amount)
			}
		}
	}

	// Ecosystem Contribution, Liquidity Exchanges
	group['ecosystem-contribution'] = Group{
		name:         'Ecosystem Contribution, Liquidity Exchanges'
		distribution: 0.04
		done:         liquidity_amount
	}

	// Technology Acquisition + Starting Team (40p)
	group['technology'] = Group{
		name:         'Technology Acquisition + Starting Team'
		distribution: 0.07
		done:         290000000
	}

	// Advisors, Founders & Team
	group['advisors-founders'] = Group{
		name:         'Advisors, Founders & Team'
		distribution: 0.06
	}

	sum := group['farming-rewards-2018'].done + group['ecosystem-grants'].done +
		group['promotion-marketing'].done + group['ecosystem-contribution'].done +
		group['technology'].done

	group['advisors-founders'].done = total_tokens - sum

	return group
}

fn parse_balance(bal Raw_Balance) Balance {
	return Balance{
		amount: parsef(bal.amount)
		asset:  bal.asset
	}
}

fn account_info(account Raw_Account) Account {
	mut final := Account{
		address: account.address
	}

	for bal in account.balances {
		final.balances << parse_balance(bal)
	}

	for vest in account.vesting_accounts {
		mut vesting := VestingAccount{
			address:       vest.address
			vestingscheme: vest.vestingscheme
		}

		for bal in vest.balances {
			vesting.balances << parse_balance(bal)
		}

		final.vesting_accounts << vesting
	}

	for locking in account.locked_amounts {
		mut locked := LockedAmount{
			address:      locking.address
			locked_until: locking.locked_until
		}

		for bal in locking.balances {
			locked.balances << parse_balance(bal)
		}

		final.locked_amounts << locked
	}

	return final
}

pub fn load_tokens() ?StatsTFT {
	mut hc := httpcache.newcache()

	urltft := 'https://statsdata.threefoldtoken.com/stellar_stats/api/stats?detailed=true'
	urltfta := 'https://statsdata.threefoldtoken.com/stellar_stats/api/stats?detailed=true&tokencode=TFTA'

	// console.print_debug("[+] fetching tokens data from redis")
	rtft := hc.getex(urltft, 86400)?
	rtfta := hc.getex(urltfta, 86400)?

	// extra stellar account for missing account in tft
	addac := 'GB2C5HCZYWNGVM6JGXDWQBJTMUY4S2HPPTCAH63HFAQVL2ALXDW7SSJ7'
	addurl := account_url(addac)
	rstel := hc.getex(addurl, 86400)?

	tft := json.decode(Raw_StatsTFT, rtft) or {
		console.print_debug('Failed to decode json (statsdata: ${urltft})')
		return StatsTFT{}
	}

	tfta := json.decode(Raw_StatsTFT, rtfta) or {
		console.print_debug('Failed to decode json (statsdata: ${urltfta})')
		return StatsTFT{}
	}

	stellar := json.decode(Raw_StellarAccount, rstel) or {
		console.print_debug('Failed to decode json (account: ${addurl})')
		return StatsTFT{}
	}

	merged := parse(tft, tfta, stellar)

	return merged
}

pub fn load_account(accid string) ?Account {
	mut hc := httpcache.newcache()

	// console.print_debug("[+] fetching account data from redis")
	accurl := account_url(accid)
	raccount := hc.getex(accurl, 86400)?

	account := json.decode(Raw_Account, raccount) or {
		console.print_debug('Failed to decode json (stellar: ${accurl})')
		return Account{}
	}

	nicer := account_info(account)

	return nicer
}
