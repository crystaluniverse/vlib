# Example initialization of my twinsafe


This is used to configure my initial twin, othertwins can also come from the network but for now we get it from heroscript actions.

```js

!!twinsafe.mytwin_define name:main
    privkey:'mnemonics ...'
    description:'...'

!!twinsafe.mytwin_define name:test1
    privkey:'mnemonics ...'
    description:'...'

!!twinsafe.mytwin_define name:test1
    generate:1
    description:'...'

!!twinsafe.othertwin_define name:anna1
    pukkey:'...'
    description:'...'
    conn_type:'ipv6'
    addr:'...'

!!twinsafe.othertwin_define name:juma1
    pukkey:'...'
    description:'...'
    conn_type:'redis'
    addr:'...'


```