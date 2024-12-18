# ${args.name}

${args.title}

To get started

```vlang

@if args.cat == .installer

import freeflowuniverse.crystallib.installers.something.${args.name} as ${args.name}_installer

heroscript:="
!!${args.name}.configure name:'test'
	password: '1234'
	port: 7701

!!${args.name}.start name:'test' reset:1 
"

${args.name}_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= ${args.name}_installer.get()!
//installer.start(reset:true)!

@else

import freeflowuniverse.crystallib.clients. ${args.name}

mut client:= ${args.name}.get()!

client...

@end



```

## example heroscript

@if args.cat == .installer
```hero
!!${args.name}.configure
    homedir: '/home/user/${args.name}'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```
@else
```hero
!!${args.name}.configure
    secret: '...'
    host: 'localhost'
    port: 8888
```
@end


