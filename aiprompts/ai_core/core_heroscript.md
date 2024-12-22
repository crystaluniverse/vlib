# instructions how to work with heroscript in vlang

## heroscript

Heroscript is our small scripting language which has following structure

an example of a heroscript is

```heroscript

!!mailclient.configure
	name: 'myname'
	host: 'localhost'
	port: 25
	secure: 1
	reset: 1 
	description: '
		a description can be multiline

		like this
		'

```

Notice how:
- every action starts with !!
	- the first part is the actor, mailclient in this case
	- the 2e part is the action name, configure in this case
- multilines are supported see the description field

## how to process heroscript in Vlang

- heroscript can be converted to a struct,
- the methods available to get the params are in 'params' section further in this doc


```vlang
//the object which will be configured
pub struct mailclient {
pub mut:
	name string
	host string
	port int	
	secure bool
	description string
}

mut plbook := playbook.new(text: $the_heroscript_from_above)!
play_mailclient(mut plbook)! //see below in vlang block there it all happens

pub fn play_mailclient(mut plbook playbook.PlayBook) ! {

	//find all actions are !!$actor.$actionname.  in this case above the actor is !!mailclient, we check with the fitler if it exists, if not we return
	mailclient_actions := plbook.find(filter: 'mailclient.')!
	for action in mailclient_actions {
		if action.name == "configure"{
			mut p := action.params
			mut obj := mailclientScript{
				//INFO: all details about the get methods can be found in 'params get methods' section
				name : p.get('name')! //will give error if not exist			
				homedir : p.get('homedir')!
				title : p.get_default('title', 'My Hero DAG')!  //uses a default if not set
				reset : p.get_default_false('reset') 
				start : p.get_default_true('start')
				colors : p.get_list('colors')
				description : p.get_default('description','')!					
			}
		}

	}
}


}


## params get methods (param getters)

above in the p.get... 

below you can find the methods which can be used on the params

```vlang

exists(key_ string) bool

//check if arg exist (arg is just a value in the string e.g. red, not value:something) 
exists_arg(key_ string) bool

//see if the kwarg with the key exists if yes return as string trimmed
get(key_ string) !string

//return the arg with nr, 0 is the first    
get_arg(nr int) !string

//return arg, if the nr is larger than amount of args, will return the defval
get_arg_default(nr int, defval string) !string

get_default(key string, defval string) !string

get_default_false(key string) bool

get_default_true(key string) bool

get_float(key string) !f64

get_float_default(key string, defval f64) !f64

get_from_hashmap(key_ string, defval string, hashmap map[string]string) !string

get_int(key string) !int

get_int_default(key string, defval int) !int

//Looks for a list of strings in the parameters. ',' are used as deliminator to list
get_list(key string) ![]string

get_list_default(key string, def []string) ![]string

get_list_f32(key string) ![]f32

get_list_f32_default(key string, def []f32) []f32

get_list_f64(key string) ![]f64

get_list_f64_default(key string, def []f64) []f64

get_list_i16(key string) ![]i16

get_list_i16_default(key string, def []i16) []i16

get_list_i64(key string) ![]i64

get_list_i64_default(key string, def []i64) []i64

get_list_i8(key string) ![]i8

get_list_i8_default(key string, def []i8) []i8

get_list_int(key string) ![]int

get_list_int_default(key string, def []int) []int

get_list_namefix(key string) ![]string

get_list_namefix_default(key string, def []string) ![]string

get_list_u16(key string) ![]u16

get_list_u16_default(key string, def []u16) []u16

get_list_u32(key string) ![]u32

get_list_u32_default(key string, def []u32) []u32

get_list_u64(key string) ![]u64

get_list_u64_default(key string, def []u64) []u64

get_list_u8(key string) ![]u8

get_list_u8_default(key string, def []u8) []u8

get_map() map[string]string

get_path(key string) !string

get_path_create(key string) !string

get_percentage(key string) !f64

get_percentage_default(key string, defval string) !f64

//convert GB, MB, KB to bytes e.g. 10 GB becomes bytes in u64
get_storagecapacity_in_bytes(key string) !u64

get_storagecapacity_in_bytes_default(key string, defval u64) !u64

get_storagecapacity_in_gigabytes(key string) !u64

//Get Expiration object from time string input input can be either relative or absolute## Relative time
get_time(key string) !ourtime.OurTime

get_time_default(key string, defval ourtime.OurTime) !ourtime.OurTime

get_time_interval(key string) !Duration

get_timestamp(key string) !Duration

get_timestamp_default(key string, defval Duration) !Duration

get_u32(key string) !u32

get_u32_default(key string, defval u32) !u32

get_u64(key string) !u64

get_u64_default(key string, defval u64) !u64

get_u8(key string) !u8

get_u8_default(key string, defval u8) !u8

```
