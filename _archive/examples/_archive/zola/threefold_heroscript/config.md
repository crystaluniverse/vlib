```js

!!context.configure
    name:'test'
    // coderoot:'/tmp/code'
    // interactive:true

!!websites.configure
	buildroot:'~/hero/var/wsbuild'
	publishroot:'~/hero/www/'
	install:true
	reset:true

```