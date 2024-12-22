module httpconnection

import net.http { Header, Method }

pub enum DataFormat {
	json           // application/json
	urlencoded     //
	multipart_form //
}

@[params]
pub struct Request {
pub mut:
	method        Method
	prefix        string
	id            string
	params        map[string]string
	data          string
	cache_disable bool // do not put this default on true, this is set on the connection, this is here to be overruled in specific cases
	header        ?Header
	dict_key      string // if the return is a dict, then will take the element out of the dict with the key and process further
	list_dict_key string // if the output is a list of dicts, then will process each element of the list to take the val with key out of that dict
	debug         bool
	dataformat    DataFormat
}
