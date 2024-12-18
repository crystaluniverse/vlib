# meilisearch



To get started

```vlang


import freeflowuniverse.crystallib.installers.db.meilisearch as meilisearchinstaller

heroscript:="
!!meilisearch.configure name:'test'
    masterkey: '1234'
    port: 7701

!!meilisearch.start name:'test' reset:1 
"

meilisearchinstaller.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= meilisearch_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!meilisearch.configure
    name:'default'
    path: '{HOME}/hero/var/meilisearch/default'
    masterkey: ''
    host: 'localhost'
    port: 7700
    production: 0

```


