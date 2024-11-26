module livekit

import os
import freeflowuniverse.crystallib.osal

fn testsuite_begin() ! {
    osal.load_env_file('${os.dir(@FILE)}/.env')!
}

fn new_test_client() Client {
    return new(
        url: os.getenv('LIVEKIT_URL')
	    api_key: os.getenv('LIVEKIT_API_KEY')
	    api_secret: os.getenv('LIVEKIT_API_SECRET')
    )
}

fn test_client_list_rooms() ! {
    client := new_test_client()
    rooms := client.list_rooms()!
    panic(rooms)
}
