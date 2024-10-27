struct Company {
    id string
    short_code string
    name string
    current_nr_shares int
    current_share_value string
    description string
    admins string
    comments string
}

struct InvestorTool {
mut:
    companies []Company
    // ... other fields like users, investors, and investments
}

fn (mut it InvestorTool) company_define(params string) ! {
    mut p := paramsparser.new(params)!
    company := Company{
        id: p.get_default('id', '')!
        short_code: p.get_default('short_code', '')!
        name: p.get_default('name', '')!
        current_nr_shares: p.get_int('current_nr_shares')!
        current_share_value: p.get_default('current_share_value', '')!
        description: p.get_default('description', '')!
        admins: p.get_default('admins', '')!
        comments: p.get_default('comments', '')!
    }
    it.companies << company
}