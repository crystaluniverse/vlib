module investortool

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.data.currency

@[heap]
pub struct InvestmentShares {
pub mut:
	oid              string
	company_ref      string
	investor_ref     string
	nr_shares        f64
	share_class      string
	investment_value ?currency.Amount
	interest         ?currency.Amount
	description      string
	investment_date  ?ourtime.OurTime
	type_            string
	comments         []string
}

fn play_investmentshares(mut investortool InvestorTool, mut plbook playbook.PlayBook) ! {
	for mut action in plbook.find(filter: 'investortool.investment_shares_define')! {
		mut p := action.params
		mut investment_shares := InvestmentShares{
			oid:              p.get_default('oid', '')!
			company_ref:      p.get_default('company_ref', '')!.trim(' ')
			investor_ref:     p.get_default('investor_ref', '')!
			nr_shares:        p.get_float_default('nr_shares', 0)!
			share_class:      p.get_default('share_class', '')!
			investment_value: if p.exists('investment_value')
				&& p.get('investment_value')!.trim(' ').len > 0 {
				p.get_currencyamount('investment_value')!
			} else {
				none
			}
			interest:         if p.exists('interest') && p.get('interest')!.trim(' ').len > 0 {
				p.get_currencyamount('interest')!
			} else {
				none
			}
			description:      p.get_default('description', '')!
			investment_date:  if p.exists('investment_date') {
				p.get_time('investment_date')!
			} else {
				none
			}
			type_:            p.get_default('type', '')!
			comments:         p.get_list_default('comments', [])!
		}
		println(investment_shares)
		investortool.investment_shares_add(investment_shares)!
	}
}
