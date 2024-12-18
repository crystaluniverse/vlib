import os
import json

const doc_path = '${os.dir(@FILE)}/openrpc.json'
const gen_path = '${os.dir(@FILE)}/gen'

// decode openrpc document into object
mut doc_file := pathlib.get_file(path: doc_path)!
content := doc_file.read()!
object := json.decode(openrpc.OpenRPC, content)

// generate codes
model_code := object.generate_models()
handler_code := object.generate_handler()
server_code := object.generate_server()
client_code := object.generate_client()

// write code
gen_dir := pathlib.get_dir(
	path:  gen_path
	reset: true
)!

model_code.write_file()
