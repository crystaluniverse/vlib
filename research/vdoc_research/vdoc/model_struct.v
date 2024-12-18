module vdoc

@[heap]
pub struct VStruct {
pub mut:
	name       string
	vmodule    &VModule @[skip]
	comments   string // everything as comment before the struct
	properties []VStructProperty
	methods    []VStructMethod
}

pub struct VStructProperty {
pub mut:
	vmodule     &VStruct @[skip]
	name        string
	type_       string // The type of the property (string, f64, bool, etc)
	comments    string // after '//' at end of line
	default_val string
}

pub struct VStructMethod {
pub mut:
	name            string
	comments        string // after '//' at end of line
	args            []VStructMethodArg
	kwargs          []VStructMethodKWArg
	result          []VStructMethodResult
	vstruct_pointer &VStruct @[skip]
}

pub struct VStructMethodArg {
pub mut:
	name           string
	method_pointer &VStructMethod @[skip]
}

pub struct VStructMethodKWArg {
pub mut:
	name           string
	default_val    string
	method_pointer &VStructMethod @[skip]
}

pub struct VStructMethodResult {
pub mut:
	canerror       bool     // means there is !
	optional       bool     // means there is ?
	name           []string // of the return
	type_          []string // e.g. another VStruct, here is just the name or the type
	method_pointer &VStructMethod @[skip]
}
