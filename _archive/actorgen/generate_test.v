module generator

import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.core.pathlib

// generate generates actor code from model code
fn test_generate() {
	test_generator := ActorGenerator{'test'}
	mut test_code := []codemodel.CodeItem{}
	test_code = [
		codemodel.Struct{
			name:  'TestRoot1'
			attrs: [codemodel.Attribute{
				name: 'root_object'
			}]
		},
		codemodel.Struct{
			name:  'TestRoot2'
			attrs: [codemodel.Attribute{
				name: 'root_object'
			}]
		},
	]
	code := test_generator.generate(test_code)!
	str := codemodel.vgen(code)
	println(str)
	panic('ss')
}
