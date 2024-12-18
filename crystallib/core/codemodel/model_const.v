module codemodel

pub struct Const {
	name  string
	value string
}

pub fn parse_const(code_ string) !Const {
	code := code_.trim_space().all_before('\n')
	if !code.contains('=') {
		return error('code <${code_}> is not of const')
	}
	return Const{
		name:  code.split('=')[0].trim_space()
		value: code.split('=')[1].trim_space()
	}
}

pub fn parse_consts(code_ string) ![]Const {
	mut code := code_.trim_space()
	code = code.replace('const (', 'const(')

	const_codes := code.split('\n').filter(it.trim_space().starts_with('const '))

	mut consts := const_codes.map(parse_const(it)!)

	const_blocks := code.split('const(')

	if const_blocks.len == 1 {
		return consts
	}

	for i, block in const_blocks {
		if i == 0 {
			continue
		}
		stmts := block.trim_string_left('const(').all_before('\n)').trim_space().split('\n')
		consts << stmts.map(parse_const(it)!)
	}

	return consts
}
