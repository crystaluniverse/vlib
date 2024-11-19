

Each document we will sort need to have e.g. `[aac]` in the name, the aac is the id of the document

How to use

- documents can be downloaded from any source and put in a directory which is the the source of the information


## example

```v
#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import import freeflowuniverse.crystallib.conversiontools.docsorter

docsorter.sort(
    path: '/Users/despiegk1/Downloads/pdfcleaner'
    export_path: '/tmp/export'
)!



```

example instructions file:

```yaml
aaa:ourworld:kristof_bio
aab:phoenix:phoenix_digital_nation_litepaper:Litepaper of how a Digital nation can use the Hero Phone
```

the first is the id, 2nd is name of the collection, the 3e is the name, and 4e is optional description.

## usage through heroscript

> NOT IMPLEMENTED YET

```yaml

!!docsorter.settings collections_path:'' 

//the following will download the doc from google drive, will only work if doc is public available
!!docsorter.pdf_copy id:'aaa' name:'ourworld_investment_memo' type:'pdf' collection:'ourworld'
    url:'https://docs.google.com/document/d/1sjh2K6iay86H9Gd83gY04bVDSj4brxADEWQMVmDq0SQ'
    description:'OurWorld Investment Memo Nov 2024'
!!docsorter.canva_export ...
```