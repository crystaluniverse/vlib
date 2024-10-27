module investortool


struct Investor {
    id string
    name string
    code string
    description string
    user_refs string
    admins string
    comments string
}

struct InvestmentShares {
    id string
    company_ref string
    investor_ref string
    nr_shares f64
    share_class string
    investment_value string
    interest string
    description string
    investment_date string
    type string
    comments string
}

struct InvestorTool {
mut:
    investors []Investor
    investments []InvestmentShares
}

fn new_investor_tool() InvestorTool {
    return InvestorTool{
        investors: []
        investments: []
    }
}

fn (mut it InvestorTool) investor_define(params string) ! {
    mut p := paramsparser.new(params)!
    investor := Investor{
        id: p.get_default('id', '')!
        name: p.get_default('name', '')!
        code: p.get_default('code', '')!
        description: p.get_default('description', '')!
        user_refs: p.get_default('user_refs', '')!
        admins: p.get_default('admins', '')!
        comments: p.get_default('comments', '')!
    }
    it.investors << investor
}

fn (mut it InvestorTool) investment_shares_define(params string) ! {
    mut p := paramsparser.new(params)!
    investment := InvestmentShares{
        id: p.get_default('id', '')!
        company_ref: p.get_default('company_ref', '')!
        investor_ref: p.get_default('investor_ref', '')!
        nr_shares: p.get_f64('nr_shares')!
        share_class: p.get_default('share_class', '')!
        investment_value: p.get_default('investment_value', '')!
        interest: p.get_default('interest', '')!
        description: p.get_default('description', '')!
        investment_date: p.get_default('investment_date', '')!
        type: p.get_default('type', '')!
        comments: p.get_default('comments', '')!
    }
    it.investments << investment
}