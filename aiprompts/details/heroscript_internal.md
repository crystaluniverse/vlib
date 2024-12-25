
## how internally a heroscript gets parsed for params

- example to show how a heroscript gets parsed in action with params
- params are part of action object

```heroscript
example text to parse (heroscript)

id:a1 name6:aaaaa
name:'need to do something 1' 
description:
    '
    ## markdown works in it
    description can be multiline
    lets see what happens

    - a
    - something else

    ### subtitle
    '

name2:   test
name3: hi 
name10:'this is with space'  name11:aaa11

name4: 'aaa'

//somecomment
name5:   'aab'
```

the params are part of the action and are represented as follow for the above:

```vlang
Params{
    params: [Param{
        key: 'id'
        value: 'a1'
    }, Param{
        key: 'name6'
        value: 'aaaaa'
    }, Param{
        key: 'name'
        value: 'need to do something 1'
    }, Param{
        key: 'description'
        value: '## markdown works in it

                description can be multiline
                lets see what happens

                - a
                - something else

                ### subtitle
                '
        }, Param{
            key: 'name2'
            value: 'test'
        }, Param{
            key: 'name3'
            value: 'hi'
        }, Param{
            key: 'name10'
            value: 'this is with space'
        }, Param{
            key: 'name11'
            value: 'aaa11'
        }, Param{
            key: 'name4'
            value: 'aaa'
        }, Param{
            key: 'name5'
            value: 'aab'
        }]
    }
```