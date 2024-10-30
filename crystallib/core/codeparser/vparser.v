module codeparser

import v.ast
import v.parser
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.codemodel { Module, CodeFile, CodeItem, Function, Import, Param, Result, Struct, StructField, Sumtype, Type, parse_consts, parse_import }
import v.pref

// VParser holds configuration of parsing
// has methods that implement parsing
@[params]
pub struct VParser {
pub:
	exclude_dirs  []string // directories to be excluded from parsing
	exclude_files []string // files to be excluded from parsing
	only_pub      bool     // whether to only parse public functions and structs
	recursive     bool     // whether subdirs should be parsed as well
}

// parse_v takes in a path to parse V code from and
// vparser configuration params, returns a list of parsed codeitems
pub fn parse_v(path_ string, vparser VParser) ![]CodeItem {
	mut path := pathlib.get(path_)

	$if debug {
		console.print_debug('Parsing path `${path.path}` with cofiguration:\n${vparser}\n')
	}

	if !path.exists() {
		return error('Path `${path.path}` doesn\'t exist.')
	}

	path.check()
	mut table := ast.new_table()
	return vparser.parse_vpath(mut path, mut table)!
}

// parse_vpath parses the v code files and returns codeitems in a given path
// can be recursive or not based on the parsers configuration
fn (vparser VParser) parse_vpath(mut path pathlib.Path, mut table ast.Table) ![]CodeItem {
	mut code := []CodeItem{}
	// mut table := ast.new_table()
	// fpref := &pref.Preferences{ // preferences for parsing
	// 	is_fmt: true
	// }
	if path.is_dir() {
		dir_is_excluded := vparser.exclude_dirs.any(path.path.ends_with(it))
		if dir_is_excluded {
			return code
		}

		if vparser.recursive {
			// parse subdirs if configured recursive
			mut flist := path.list(recursive: true)!
			for mut subdir in flist.paths {
				if subdir.is_dir() {
					code << vparser.parse_vpath(mut subdir, mut table)!
				}
			}
		}

		mut fl := path.list(recursive: false)!
		for mut file in fl.paths {
			if !file.is_dir() {
				code << vparser.parse_vpath(mut file, mut table)!
			}
		}
	} else if path.is_file() {
		file_is_excluded := vparser.exclude_files.any(path.path.ends_with(it))
		// todo: use pathlib list regex param to filter non-v files
		if file_is_excluded || !path.path.ends_with('.v') {
			return code
		}
		code << vparser.parse_vfile(path.path, mut table)
	} else {
		return error('Path being parsed must either be a directory or a file.')
	}
	// codemodel.inflate_types(mut code)
	return code
}

// parse_vfile parses and returns code items from a v code file
pub fn parse_file(path string, vparser VParser) !CodeFile {
	mut file := pathlib.get_file(path: path)!
	mut table := ast.new_table()
	items := vparser.parse_vfile(file.path, mut table)
	return CodeFile{
		name: file.name().trim_string_right('.v')
		imports: parse_imports(file.read()!)
		consts: parse_consts(file.read()!)!
		items: items
	}
}

pub fn parse_imports(code string) []Import {
	return code.split('\n').filter(it.starts_with('import ')).map(parse_import(it))
}

// parse_vfile parses and returns code items from a v code file
fn (vparser VParser) parse_vfile(path string, mut table ast.Table) []CodeItem {
	$if debug {
		console.print_debug('Parsing file `${path}`')
	}
	mut code := []CodeItem{}

	// mut table := ast.new_table()
	fpref := &pref.Preferences{ // preferences for parsing
		is_fmt: true
	}
	file_ast := parser.parse_file(path, mut table, .parse_comments, fpref)
	mut file := pathlib.get_file(path: path) or { panic(err) }
	file_text := file.read() or { panic(err) }
	mut preceeding_comments := []ast.Comment{}

	for stmt in file_ast.stmts {
		// code block from vlib/v/doc/doc.v
		if stmt is ast.ExprStmt {
			// Collect comments
			if stmt.expr is ast.Comment {
				preceeding_comments << stmt.expr as ast.Comment
				continue
			}
		}
		if stmt is ast.FnDecl {
			fn_decl := stmt as ast.FnDecl
			if fn_decl.attrs.len > 0 {
				openrpc_attrs := fn_decl.attrs.filter(it.name == 'openrpc')
				{
					if openrpc_attrs.any(it.arg == 'exclude') {
						continue
					}
				}
			}
			if fn_decl.is_pub || !vparser.only_pub {
				code << CodeItem(vparser.parse_vfunc(
					fn_decl: fn_decl
					table: table
					comments: preceeding_comments
					text: file_text
				))
			}
			preceeding_comments = []ast.Comment{}
		} else if stmt is ast.TypeDecl {
			if stmt is ast.SumTypeDecl {
				sumtype_decl := stmt as ast.SumTypeDecl
				if sumtype_decl.attrs.len > 0 {
					openrpc_attrs := sumtype_decl.attrs.filter(it.name == 'openrpc')
					{
						if openrpc_attrs.any(it.arg == 'exclude') {
							continue
						}
					}
				}
				if sumtype_decl.is_pub || !vparser.only_pub {
					code << CodeItem(vparser.parse_vsumtype(
						sumtype_decl: sumtype_decl
						table: table
						comments: preceeding_comments
					))
				}
				preceeding_comments = []ast.Comment{}
			}
		} else if stmt is ast.StructDecl {
			struct_decl := stmt as ast.StructDecl
			if struct_decl.attrs.len > 0 {
				openrpc_attrs := struct_decl.attrs.filter(it.name == 'openrpc')
				{
					if openrpc_attrs.any(it.arg == 'exclude') {
						continue
					}
				}
			}
			if struct_decl.is_pub || !vparser.only_pub {
				code << CodeItem(vparser.parse_vstruct(
					struct_decl: struct_decl
					table: table
					comments: preceeding_comments
				))
			}
			preceeding_comments = []ast.Comment{}
		}
	}
	return code
}

// parse_vfile parses and returns code items from a v code file
pub fn parse_module(path_ string, vparser VParser) !Module {
	mut path := pathlib.get(path_)
	if !path.exists() {
		return error('Path `${path.path}` doesn\'t exist.')
	}

	mut table := ast.new_table()
	mut code := []CodeFile{}
	// fpref := &pref.Preferences{ // preferences for parsing
	// 	is_fmt: true
	// }
	mut mod := Module {
		name: path.name()
	}
	if path.is_dir() {
		dir_is_excluded := vparser.exclude_dirs.any(path.path.ends_with(it))
		if dir_is_excluded {
			return Module {
				...mod
				files: code
			}
		}

		if vparser.recursive {
			return error('recursive module parsing not yet supported')
		}

		mut fl := path.list(recursive: false)!
		for mut file in fl.paths {
			if !file.is_dir() {
				code << parse_file(file.path, vparser)!
			}
		}
	} else if path.is_file() {
		file_is_excluded := vparser.exclude_files.any(path.path.ends_with(it))
		// todo: use pathlib list regex param to filter non-v files
		if file_is_excluded || !path.path.ends_with('.v') {
			return Module{
				...mod
				files:code
			}
		}
		code << parse_file(path.path, vparser)!
	} else {
		return error('Path being parsed must either be a directory or a file.')
	}
	// codemodel.inflate_types(mut code)
	return Module{
		...mod
		files: code
	}
}

@[params]
struct VFuncArgs {
	comments []ast.Comment // v comments that belong to the function
	fn_decl  ast.FnDecl    // v.ast parsed function declaration
	table    &ast.Table    // ast table used for getting typesymbols from
	text     string
}

// parse_vfunc parses function args into function struct
pub fn (vparser VParser) parse_vfunc(args VFuncArgs) Function {
	$if debug {
		console.print_debug('Parsing function: ${args.fn_decl.short_name}')
	}

	// get function params excluding receiver
	receiver_name := args.fn_decl.receiver.name
	receiver_type := args.table.type_to_str(args.fn_decl.receiver.typ).all_after_last('.')
	fn_params := args.fn_decl.params.filter(it.name != receiver_name)

	receiver := Param{
		name: receiver_name
		typ: Type{
			symbol: receiver_type
		}
		mutable: args.fn_decl.rec_mut
	}

	params := vparser.parse_params(
		comments: args.comments
		params: fn_params
		table: args.table
	)

	result := vparser.parse_result(
		comments: args.comments
		return_type: args.fn_decl.return_type
		table: args.table
	)

	mut fn_comments := []string{}
	for comment in args.comments.map(it.text.trim_string_left('\u0001').trim_space()) {
		if !comment.starts_with('-') && !comment.starts_with('returns') {
			fn_comments << comment.trim_string_left('${args.fn_decl.short_name} ')
		}
	}

	text_lines := args.text.split('\n')
	fn_lines := text_lines.filter(it.contains('fn') && it.contains(' ${args.fn_decl.short_name}('))
	fn_line := fn_lines[0] or { panic('this should never happen') }
	line_i := text_lines.index(fn_line)
	end_i := line_i + text_lines[line_i..].index('}')

	fn_text := text_lines[line_i..end_i + 1].join('\n')
	// mut fn_index := args.text.index(args.fn_decl.short_name) or {panic('this should never happen1')}
	// text_cropped := args.text[..fn_index] or {panic('this should never happen2')}
	// fn_start := text_cropped.last_index('fn ') or {panic('this should never happen3 \n-${text_cropped}')}
	// fn_text := args.text[fn_start..] or {panic('this should never happen4')}
	fn_parsed := codemodel.parse_function(fn_text) or { panic(err) }

	return Function{
		name: args.fn_decl.short_name
		description: fn_comments.join(' ')
		mod: args.fn_decl.mod
		receiver: receiver
		params: params
		result: fn_parsed.result
		body: fn_parsed.body
	}
}

@[params]
struct ParamsArgs {
	comments []ast.Comment // comments of the function
	params   []ast.Param   // ast type of what function returns
	table    &ast.Table    // ast table for getting type names
}

// parse_params parses ast function parameters into function parameters
fn (vparser VParser) parse_params(args ParamsArgs) []Param {
	mut params := []Param{}
	for param in args.params {
		mut description := ''
		// parse comment line that describes param
		for comment in args.comments {
			if start := comment.text.index('- ${param.name}: ') {
				description = comment.text[start..].trim_string_left('- ${param.name}: ')
			}
		}

		params << Param{
			name: param.name
			description: description
			typ: Type{
				symbol: args.table.type_to_str(param.typ).all_after_last('.')
			}
		}
	}
	return params
}

@[params]
struct ParamArgs {
	comments []ast.Comment // comments of the function
	param    ast.Param     // ast type of what function returns
	table    &ast.Table    // ast table for getting type names
}

// parse_params parses ast function parameters into function parameters
fn (vparser VParser) parse_param(args ParamArgs) Param {
	mut description := ''
	// parse comment line that describes param
	for comment in args.comments {
		if start := comment.text.index('- ${args.param.name}: ') {
			description = comment.text[start..].trim_string_left('- ${args.param.name}: ')
		}
	}

	return Param{
		name: args.param.name
		description: description
		typ: Type{
			symbol: args.table.type_to_str(args.param.typ).all_after_last('.')
		}
	}
}

struct ReturnArgs {
	comments    []ast.Comment // comments of the function
	return_type ast.Type      // v.ast type of what function returns
	table       &ast.Table    // v.ast table for getting type names
}

// parse_result parses a function's comments and return type
// returns a result struct that represents what the function's result is
fn (vparser VParser) parse_result(args ReturnArgs) Result {
	comment_str := args.comments.map(it.text).join('')

	// parse comments to get return name and description	
	mut name := ''
	mut description := ''
	if start := comment_str.index('returns') {
		mut end := comment_str.index_after('.', start)
		if end == -1 {
			end = comment_str.len
		}
		return_str := comment_str[start..end].trim_string_left('returns ')

		split := return_str.split(', ')
		name = split[0]
		if split.len > 1 {
			description = split[1..].join(', ')
		}
	}
	return_symbol := args.table.type_to_str(args.return_type).all_after_last('.')

	return Result{
		name: name
		description: description
		typ: Type{
			symbol: return_symbol
		}
	}
}

// parse_params parses ast function parameters into function parameters
fn (vparser VParser) parse_type(typ ast.Type, table &ast.Table) Type {
	type_str := table.type_to_str(typ).all_after_last('.')
	return Type{
		symbol: type_str
	}
}

struct VStructArgs {
	comments    []ast.Comment  // comments that belong to the struct declaration
	struct_decl ast.StructDecl // v.ast Struct declaration for struct being parsed
	table       &ast.Table     // v.ast table for getting type names
}

// parse_params parses struct args into struct
fn (vparser VParser) parse_vstruct(args VStructArgs) Struct {
	$if debug {
		console.print_debug('Parsing struct: ${args.struct_decl.name}')
	}

	comments := args.comments.map(it.text.trim_string_left('\u0001').trim_space())
	mut fields := vparser.parse_fields(args.struct_decl.fields, args.table)
	fields << vparser.parse_embeds(args.struct_decl.embeds, args.table)
	return Struct{
		name: args.struct_decl.name.all_after_last('.')
		description: comments.join(' ')
		fields: fields
		mod: args.struct_decl.name.all_before_last('.')
		attrs: args.struct_decl.attrs.map(codemodel.Attribute{ name: it.name })
		is_pub: args.struct_decl.is_pub
	}
}

struct VSumTypeArgs {
	comments     []ast.Comment   // comments that belong to the struct declaration
	sumtype_decl ast.SumTypeDecl // v.ast Struct declaration for struct being parsed
	table        &ast.Table      // v.ast table for getting type names
}

// parse_params parses struct args into struct
fn (vparser VParser) parse_vsumtype(args VSumTypeArgs) Sumtype {
	$if debug {
		console.print_debug('Parsing sumtype: ${args.sumtype_decl.name}')
	}

	comments := args.comments.map(it.text.trim_string_left('\u0001').trim_space())

	return Sumtype{
		name: args.sumtype_decl.name.all_after_last('.')
		description: comments.join(' ')
		types: vparser.parse_variants(args.sumtype_decl.variants, args.table)
	}
}

// parse_fields parses ast struct fields into struct fields
fn (vparser VParser) parse_fields(fields []ast.StructField, table &ast.Table) []StructField {
	mut fields_ := []StructField{}
	for field in fields {
		mut anon_struct := Struct{}
		if table.type_to_str(field.typ).all_after_last('.').starts_with('_VAnon') {
			anon_struct = vparser.parse_vstruct(
				table: table
				struct_decl: field.anon_struct_decl
			)
		}

		description := field.comments.map(it.text.trim_string_left('\u0001').trim_space()).join(' ')
		fields_ << StructField{
			attrs: field.attrs.map(codemodel.Attribute{
				name: it.name
				has_arg: it.has_arg
				arg: it.arg
			})
			name: field.name
			anon_struct: anon_struct
			description: description
			typ: Type{
				symbol: table.type_to_str(field.typ).all_after_last('.')
				is_array: table.type_to_str(field.typ).contains('[]')
				is_map: table.type_to_str(field.typ).contains('map[')
			}
			is_pub: field.is_pub
			is_mut: field.is_mut
			default: field.default_val
		}
	}
	return fields_

	// return fields.map(
	// 	StructField{
	// 		name: it.name
	// 		typ: Type{
	// 			symbol: table.type_to_str(it.typ).all_after_last('.')
	// 		}
	// 	}
	// )
}

// parse_embeds parses ast.embeds into struct fields
// TODO: Support requiresive fields
fn (vparser VParser) parse_embeds(embeds []ast.Embed, table &ast.Table) []StructField {
	mut fields := []StructField{}
	for embed in embeds {
		$if debug {
			console.print_debug('Parsing embed: ${table.sym(embed.typ).info}')
		}
		embed_info := table.sym(embed.typ).info
		if embed_info is ast.Struct {
			// embeds: vparser.parse_embeds(embed_info.embeds, table)
			fields << vparser.parse_fields(embed_info.fields, table)
		}
	}
	return fields
}

// parse_fields parses ast struct fields into struct fields
fn (vparser VParser) parse_variants(variants []ast.TypeNode, table &ast.Table) []Type {
	mut types := []Type{}
	for variant in variants {
		types << Type{
			symbol: table.type_to_str(variant.typ).all_after_last('.')
		}
	}
	return types
}
