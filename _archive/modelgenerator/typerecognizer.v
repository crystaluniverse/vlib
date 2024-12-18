module modelgenerator

// import encoding.binary as bin
// import time

pub fn (mut generator CodeGenerator) typerecognizer(mut domain Domain, mut actor Actor, ffield Field) !CRType {
	mut txt := ffield.typestr
	mut islist := false
	if txt.starts_with('[]') {
		islist = true
		txt = txt.all_after(']')
	}
	match txt {
		'u8' {
			return CRType{
				list:  islist
				cat:   .u8
				size:  1
				model: &Model{}
			}
		}
		'u16' {
			return CRType{
				list:  islist
				cat:   .u16
				size:  2
				model: &Model{}
			}
		}
		'u32' {
			return CRType{
				list:  islist
				cat:   .u32
				size:  4
				model: &Model{}
			}
		}
		'u64' {
			return CRType{
				list:  islist
				cat:   .u64
				size:  8
				model: &Model{}
			}
		}
		'int' {
			return CRType{
				list:  islist
				cat:   .int
				size:  4
				model: &Model{}
			}
		}
		'i64' {
			return CRType{
				list:  islist
				cat:   .i64
				size:  8
				model: &Model{}
			}
		}
		'string' {
			return CRType{
				list:  islist
				cat:   .string
				model: &Model{}
			}
		}
		'time' {
			return CRType{
				list:  islist
				cat:   .time
				size:  8
				model: &Model{}
			}
		}
		'time.Time' {
			return CRType{
				list:  islist
				cat:   .time
				size:  8
				model: &Model{}
			}
		}
		else {
			if ffield.modellocation.len > 0 {
				mut model := actor.model_get_priority(mut generator, mut domain, ffield.modellocation)!
				return CRType{
					list:  islist
					cat:   .object
					model: &model
				}
			} else {
				return error('cannot define type, modellocation was not specified or other unrecognized type for ${txt} for field:${ffield}')
			}
		}
	}
}
