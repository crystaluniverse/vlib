# @{employee.name}


`@{employee.description}`

> department:  `@{employee.department}`

**Cost To The Company:**  

`@{employee.cost}`


@if employee.cost_percent_revenue > 0.0

**Cost Percent Revenue:**  

`@{employee.cost_percent_revenue}%`

@end


@if employee.nrpeople.len > 1

**Number of People in this group** 

`@{employee.nrpeople}`

@end
