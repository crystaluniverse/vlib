module bizmodel

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.core.texttools

// populate the params for hr .
// !!hr.funding_define .
// - name, e.g. for a specific person .
// - descr: description of the funding .
// - investment is month:amount,month:amount, ... .
// - type: loan or capital .
fn (mut m BizModel) funding_define_action(action Action) ! {
	mut name := action.params.get_default('name', '')!
	mut descr := action.params.get_default('descr', '')!
	if descr.len == 0 {
		descr = action.params.get('description')!
	}
	if name.len == 0 {
		// make name ourselves
		name = texttools.name_fix(descr) // TODO:limit len
	}
	mut investment := action.params.get_default('investment', '0.0')!
	fundingtype := action.params.get_default('type', 'capital')!

	m.sheet.row_new(
		name:        'funding_${name}'
		growth:      investment
		tags:        'funding type:${fundingtype}'
		descr:       descr
		extrapolate: false
	)!
}

fn (mut sim BizModel) funding_total() ! {
	sim.sheet.group2row(
		name:    'funding_total'
		include: ['funding']
		tags:    'pl'
		descr:   'total funding'
	)!
}
