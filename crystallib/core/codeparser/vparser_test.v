module codeparser

import freeflowuniverse.crystallib.core.codemodel { CodeItem, Function, Struct }
import os
import freeflowuniverse.crystallib.ui.console

const testpath = os.dir(@FILE) + '/testdata'

// is a map of test files used in these tests and their complete codeitems
// used to make assertions and verify test outputs
const testcode = {
	'anotherfile.v': [
		CodeItem(Function{
			name:        'anotherfile_func0'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata.flatdir'
			description: 'is the first function of file'
			params:      []
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'void'
				}
				description: ''
				name:        ''
			}
			has_return:  false
		}),
		CodeItem(Function{
			name:        'anotherfile_func1'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata.flatdir'
			description: 'is the second function of file'
			params:      [
				codemodel.Param{
					required:    false
					description: 'a name that the function will do nothing with'
					name:        'name'
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
			]
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'void'
				}
				description: ''
				name:        ''
			}
			has_return:  false
		}),
		CodeItem(Struct{
			name:        'AnotherfileStruct0'
			description: 'AnotherfileStruct0 defines the configuration params of anotherfile_func2'
			mod:         'core.codeparser.testdata.flatdir'
			is_pub:      true
			attrs:       [
				codemodel.Attribute{
					name:    'params'
					has_arg: false
					arg:     ''
				},
			]
			fields:      [
				codemodel.StructField{
					comments:    []
					attrs:       []
					name:        'param1'
					description: ''
					anon_struct: Struct{
						name:        ''
						description: ''
						fields:      []
					}
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
				codemodel.StructField{
					comments:    []
					attrs:       []
					name:        'param2'
					description: ''
					anon_struct: Struct{
						name:        ''
						description: ''
						fields:      []
					}
					typ:         codemodel.Type{
						symbol: 'int'
					}
				},
			]
		}),
		CodeItem(Function{
			name:        'anotherfile_func2'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata.flatdir'
			description: 'is the third function of the file'
			params:      [
				codemodel.Param{
					required:    false
					description: 'configuration for anotherfile_func2'
					name:        'config'
					typ:         codemodel.Type{
						symbol: 'AnotherfileStruct0'
					}
				},
			]
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'void'
				}
				description: ''
				name:        ''
			}
			has_return:  false
		}),
		CodeItem(Struct{
			name:        'AnotherfileStruct1'
			description: ''
			mod:         'core.codeparser.testdata.flatdir'
			is_pub:      true
			fields:      [
				codemodel.StructField{
					comments:    []
					attrs:       []
					name:        'param'
					description: ''
					anon_struct: Struct{
						name:        ''
						description: ''
						fields:      []
					}
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
			]
		}),
		CodeItem(Function{
			name:        'anotherfile_func3'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata.flatdir'
			description: 'is the fourth function of the file is does something with param1 and param2 and creates AnotherfileStruct1'
			params:      [
				codemodel.Param{
					required:    false
					description: ''
					name:        'param1'
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
				codemodel.Param{
					required:    false
					description: ''
					name:        'param2'
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
			]
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'AnotherfileStruct1'
				}
				description: 'a FileStruc1 struct filled in with params 1 and 2'
				name:        'the created filestruct1'
			}
			has_return:  false
		}),
	]
	'subfile.v':     [
		CodeItem(Function{
			name:        'subfile_func0'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata.flatdir'
			description: 'is the first function of file'
			params:      []
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'void'
				}
				description: ''
				name:        ''
			}
			has_return:  false
		}),
		CodeItem(Function{
			name:        'subfile_func1'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata.flatdir'
			description: 'is the second function of file'
			params:      [
				codemodel.Param{
					required:    false
					description: 'a name that the function will do nothing with'
					name:        'name'
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
			]
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'void'
				}
				description: ''
				name:        ''
			}
			has_return:  false
		}),
		CodeItem(Struct{
			name:        'SubfileStruct0'
			description: 'SubfileStruct0 defines the configuration params of subfile_func2'
			mod:         'core.codeparser.testdata.flatdir'
			is_pub:      true
			attrs:       [
				codemodel.Attribute{
					name:    'params'
					has_arg: false
					arg:     ''
				},
			]
			fields:      [
				codemodel.StructField{
					comments:    []
					attrs:       []
					name:        'param1'
					description: ''
					anon_struct: Struct{
						name:        ''
						description: ''
						fields:      []
					}
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
				codemodel.StructField{
					comments:    []
					attrs:       []
					name:        'param2'
					description: ''
					anon_struct: Struct{
						name:        ''
						description: ''
						fields:      []
					}
					typ:         codemodel.Type{
						symbol: 'int'
					}
				},
			]
		}),
		CodeItem(Function{
			name:        'subfile_func2'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata.flatdir'
			description: 'is the third function of the file'
			params:      [
				codemodel.Param{
					required:    false
					description: 'configuration for subfile_func2'
					name:        'config'
					typ:         codemodel.Type{
						symbol: 'SubfileStruct0'
					}
				},
			]
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'void'
				}
				description: ''
				name:        ''
			}
			has_return:  false
		}),
		CodeItem(Struct{
			name:        'SubfileStruct1'
			description: ''
			mod:         'core.codeparser.testdata.flatdir'
			is_pub:      true
			fields:      [
				codemodel.StructField{
					comments:    []
					attrs:       []
					name:        'param'
					description: ''
					anon_struct: Struct{
						name:        ''
						description: ''
						fields:      []
					}
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
			]
		}),
		CodeItem(Function{
			name:        'subfile_func3'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata.flatdir'
			description: 'is the fourth function of the file is does something with param1 and param2 and creates SubfileStruct1'
			params:      [
				codemodel.Param{
					required:    false
					description: ''
					name:        'param1'
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
				codemodel.Param{
					required:    false
					description: ''
					name:        'param2'
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
			]
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'SubfileStruct1'
				}
				description: 'a FileStruc1 struct filled in with params 1 and 2'
				name:        'the created filestruct1'
			}
			has_return:  false
		}),
	]
	'file.v':        [
		CodeItem(Function{
			name:        'file_func0'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata'
			description: 'is the first function of file'
			params:      []
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'void'
				}
				description: ''
				name:        ''
			}
			has_return:  false
		}),
		CodeItem(Function{
			name:        'file_func1'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata'
			description: 'is the second function of file'
			params:      [
				codemodel.Param{
					required:    false
					description: 'a name that the function will do nothing with'
					name:        'name'
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
			]
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'void'
				}
				description: ''
				name:        ''
			}
			has_return:  false
		}),
		CodeItem(Struct{
			name:        'FileStruct0'
			description: 'FileStruct0 defines the configuration params of file_func2'
			mod:         'core.codeparser.testdata'
			is_pub:      true
			attrs:       [
				codemodel.Attribute{
					name:    'params'
					has_arg: false
					arg:     ''
				},
			]
			fields:      [
				codemodel.StructField{
					comments:    []
					attrs:       []
					name:        'param1'
					description: ''
					anon_struct: Struct{
						name:        ''
						description: ''
						fields:      []
					}
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
				codemodel.StructField{
					comments:    []
					attrs:       []
					name:        'param2'
					description: ''
					anon_struct: Struct{
						name:        ''
						description: ''
						fields:      []
					}
					typ:         codemodel.Type{
						symbol: 'int'
					}
				},
			]
		}),
		CodeItem(Function{
			name:        'file_func2'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata'
			description: 'is the third function of the file'
			params:      [
				codemodel.Param{
					required:    false
					description: 'configuration for file_func2'
					name:        'config'
					typ:         codemodel.Type{
						symbol: 'FileStruct0'
					}
				},
			]
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'void'
				}
				description: ''
				name:        ''
			}
			has_return:  false
		}),
		CodeItem(Struct{
			name:        'FileStruct1'
			description: ''
			fields:      []
			mod:         'core.codeparser.testdata'
			is_pub:      true
		}),
		CodeItem(Function{
			name:        'file_func3'
			receiver:    codemodel.Param{
				required:    false
				description: ''
				name:        ''
				typ:         codemodel.Type{
					symbol: 'void'
				}
			}
			mod:         'core.codeparser.testdata'
			description: 'is the fourth function of the file is does something with param1 and param2 and creates FileStruct1'
			params:      [
				codemodel.Param{
					required:    false
					description: ''
					name:        'param1'
					typ:         codemodel.Type{
						symbol: 'string'
					}
				},
				codemodel.Param{
					required:    false
					description: ''
					name:        'param2'
					typ:         codemodel.Type{
						symbol: 'int'
					}
				},
			]
			body:        ''
			result:      codemodel.Result{
				typ:         codemodel.Type{
					symbol: 'FileStruct1'
				}
				description: 'a FileStruc1 struct filled in with params 1 and 2'
				name:        'the created filestruct1'
			}
			has_return:  false
		}),
	]
}

fn test_vparse_blankdir() ! {
	os.mkdir_all('${testpath}/blankdir', os.MkdirParams{})!
	code := parse_v('${testpath}/blankdir')!
	assert code.len == 0
}

fn test_vparse_flat_directory() ! {
	code := parse_v('${testpath}/flatdir')!
	assert code.len == 12
	assert code[0] == testcode['anotherfile.v'][0]
	assert code[0..6] == testcode['anotherfile.v'][0..6], '<${code[0..6]}> vs <${testcode['anotherfile.v'][0..6]}>'
	assert code[6..12] == testcode['subfile.v'][0..6], '<${code[6..12]}> vs <${testcode['subfile.v'][0..6]}>'
}

fn test_vparse_non_recursive() ! {
	code := parse_v(testpath)!
	assert code.len == 6
	assert code[0] == testcode['file.v'][0]
	assert code[0..6] == testcode['file.v'][0..6], '<${code[0..6]}> vs <${testcode['file.v'][0..6]}>'
}

fn test_vparse_recursive() ! {
	$if debug {
		console.print_debug('\nTEST: test_vparse_recursive\n')
	}
	code := parse_v(testpath, recursive: true)!
	assert code.len == 18
	assert code[0..6] == testcode['anotherfile.v'][0..6]
	assert code[6..12] == testcode['subfile.v'][0..6]
	assert code[12..18] == testcode['file.v'][0..6]
}

fn test_vparse_exclude_directories() ! {
	code := parse_v(testpath,
		recursive:    true
		exclude_dirs: ['flatdir']
	)!
	assert code.len == 6
	assert code[0..6] == testcode['file.v'][0..6]
}

fn test_vparse_exclude_files() ! {
	code := parse_v(testpath,
		recursive:     true
		exclude_files: ['flatdir/anotherfile.v']
	)!
	assert code.len == 12
	assert code[0..6] == testcode['subfile.v'][0..6]
	assert code[6..12] == testcode['file.v'][0..6]
}

fn test_vparse_only_public() ! {
	code := parse_v(testpath,
		recursive: true
		only_pub:  true
	)!

	// first function of each code file is private so should skip those
	assert code.len == 15
	assert code[0..5] == testcode['anotherfile.v'][1..6]
	assert code[5..10] == testcode['subfile.v'][1..6]
	assert code[10..15] == testcode['file.v'][1..6]
}
