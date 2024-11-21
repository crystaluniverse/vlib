
## use virtual env

```v
import freeflowuniverse.crystallib.lang.python
py:=python.new(name:'default')! //a python env with name default
py.update()!
py.pip("ipython")!

```

### to activate an environment and use the installed python

```bash
source ~/hero/python/default/bin/activate
```


### how to write python scripts to execute

```v

#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run


import freeflowuniverse.crystallib.lang.python
import  json


pub struct Person {
    name     string
    age      int
    is_member bool
    skills   []string
}


mut py:=python.new(name:'test')! //a python env with name test
//py.update()!
py.pip("ipython")!


nrcount:=5
//this is used in the pythonexample
cmd:=$tmpl("pythonexample.py")

mut res:=""
for i in 0..5{
	println(i)
	res=py.exec(cmd:cmd)!
    
}
//res:=py.exec(cmd:cmd)!

person:=json.decode(Person,res)!
println(person)



```

example python script which is in the pythonscripts/ dir

```py

import json

for counter in range(1, @nrcount):  # Loop from 1 to the specified param
	print(f"done_{counter}")
 

# Define a simple Python structure (e.g., a dictionary)
example_struct = {
    "name": "John Doe",
    "age": @nrcount,
    "is_member": True,
    "skills": ["Python", "Data Analysis", "Machine Learning"]
}

# Convert the structure to a JSON string
json_string = json.dumps(example_struct, indent=4)

# Print the JSON string
print("==RESULT==")
print(json_string)
```

> see `crystallib/examples/lang/python/pythonexample.vsh`


## remark

This is a slow way how to execute python, is about 2 per second on a fast machine, need to implement something where we keep the python in mem and reading from a queue e.g. redis this will go much faster, but ok for now.

see also examples dir, there is a working example

