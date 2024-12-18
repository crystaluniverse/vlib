# caddy



To get started

```vlang



import freeflowuniverse.crystallib.installers.web.caddy

mut installer:= caddy.get()!

installer.start()!




```

## example heroscript


```hero
!!caddy.install
    homedir: '/home/user/caddy'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


