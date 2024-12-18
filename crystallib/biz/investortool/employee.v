module investortool

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.data.currency

// TODO add currency and ourtime types
@[heap]
pub struct Employee {
pub mut:
	oid                string
	user_ref           string
	company_ref        string
	status             string
	start_date         ?ourtime.OurTime
	end_date           ?ourtime.OurTime
	salary             ?currency.Amount
	salary_low         ?currency.Amount
	outstanding        ?currency.Amount
	tft_grant          f64
	reward_pool_points int
	salary_low_date    ?ourtime.OurTime
	comments           string
}

fn play_employee(mut investortool InvestorTool, mut plbook playbook.PlayBook) ! {
	for mut action in plbook.find(filter: 'investortool.employee_define')! {
		mut p := action.params
		mut employee := Employee{
			oid:                p.get_default('oid', '')!
			user_ref:           p.get_default('user_ref', '')!
			company_ref:        p.get_default('company_ref', '')!
			status:             p.get_default('status', '')!
			start_date:         if p.exists('start_date') { p.get_time('start_date')! } else { none }
			end_date:           if p.exists('end_date') { p.get_time('end_date')! } else { none }
			salary:             if p.exists('salary') && p.get('salary')!.trim(' ').len > 0 {
				p.get_currencyamount('salary')!
			} else {
				none
			}
			salary_low:         if p.exists('salary_low') && p.get('salary_low')!.trim(' ').len > 0 {
				p.get_currencyamount('salary_low')!
			} else {
				none
			}
			outstanding:        if p.exists('outstanding')
				&& p.get('outstanding')!.trim(' ').len > 0 {
				p.get_currencyamount('outstanding')!
			} else {
				none
			}
			tft_grant:          p.get_float_default('tft_grant', 0.0)!
			reward_pool_points: p.get_int_default('reward_pool_points', 0)!
			salary_low_date:    if p.exists('salary_low_date') {
				p.get_time('salary_low_date')!
			} else {
				none
			}
			comments:           p.get_default('comments', '')!
		}
		println(employee)
		investortool.employee_add(employee)!
	}
}
