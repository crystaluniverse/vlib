module bizmodel

import freeflowuniverse.crystallib.biz.spreadsheet

__global (
	bizmodels shared map[string]&BizModel
)

pub fn get(name string) !&BizModel {
	rlock bizmodels {
		if name in bizmodels {
			return bizmodels[name] or { panic('bug') }
		}
	}
	return error("cann't find biz model:'${name}' in global bizmodels")
}

// get bizmodel from global
pub fn getset(name string) !&BizModel {
	lock bizmodels {
		if name !in bizmodels {
			mut sh := spreadsheet.sheet_new(name: 'bizmodel_${name}')!
			mut bizmodel := BizModel{
				sheet: sh
				name:  name
				// currencies: cs
			}
			bizmodels[bizmodel.name] = &bizmodel
		}
		return bizmodels[name] or { panic('bug') }
	}
	panic('bug')
}

pub fn set(bizmodel BizModel) {
	lock bizmodels {
		bizmodels[bizmodel.name] = &bizmodel
	}
}
