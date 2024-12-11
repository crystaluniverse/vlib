module components


pub struct Struct {
pub:
	typ   string
	fields []Field
}

pub struct Field {
pub:
	name  string
	ftype string // data type of the field (e.g., string, int, bool, map, array)
	value string // value of the field as a string
}

fn (s Struct) html() string {
	return $tmpl('templates/struct.html') // Embeds struct.html as a template
}

pub fn to_struct[T](t T) Struct {
	mut fields := []Field{}

	$for field in T.fields {
		val := t.$(field.name)
		fields << Field{
			name:  field.name
			ftype: typeof(field.typ).name // Get the type of the field as a string
			value: '${val}'  // Get the value of the field as a string
		}
	}

	return Struct{
		typ:   typeof(t).name // Get the name of the struct type
		fields: fields
	}
}