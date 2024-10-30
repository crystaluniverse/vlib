struct User {
    id string
    usercode string
    name string
    investor_ids string
    status string
    info_links string
    telnrs string
    emails string
    secret string
}

struct InvestorTool {
mut:
    users []User
    // ... other fields like investors and investments
}

fn (mut it InvestorTool) user_define(params string) ! {
    mut p := paramsparser.new(params)!
    user := User{
        id: p.get_default('id', '')!
        usercode: p.get_default('usercode', '')!
        name: p.get_default('name', '')!
        investor_ids: p.get_default('investor_ids', '')!
        status: p.get_default('status', '')!
        info_links: p.get_default('info_links', '')!
        telnrs: p.get_default('telnrs', '')!
        emails: p.get_default('emails', '')!
        secret: p.get_