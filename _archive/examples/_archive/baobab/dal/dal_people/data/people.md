# Some examples how we can populate people


```javascript
!!people.person_define id:kristof
	firstname:Kristof
	lastname:'De Spiegeleer'
    description:'
        this is a multiline description
        ...
        '
    
!!people.contact_define person:kristof 
    email:"kristof@incubaid.com"
    tel:'+3233333333'


```