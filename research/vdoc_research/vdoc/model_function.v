module vdoc

pub struct VModuleFunction {
pub mut:
    name     string     
    comments string //after '//' at end of line
    args []VModuleFunctionArg
    kwargs []VModuleFunctionKWArg
    result []VModuleFunctiondResult
    module_pointer &VModule @[skip]
}

pub struct VModuleFunctionArg {
pub mut:
    name     string 
    function_pointer &VStructMethod @[skip]
}

pub struct VModuleFunctionKWArg {
pub mut:
    name     string 
    default_val string
    function_pointer &VStructMethod @[skip]
}

pub struct VModuleFunctiondResult {
pub mut:
    canerror bool //means there is !
    optional bool //means there is ?
    name     string //of the return
    type_    string //e.g. another VStruct, here is just the name or the type
    function_pointer &VStructMethod @[skip]
}
