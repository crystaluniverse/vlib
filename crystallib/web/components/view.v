module components

import freeflowuniverse.crystallib.data.markdownparser.elements

pub interface IView {
    html() string
}

pub struct View {
pub mut:
    head Head
    layout ILayout
}

pub fn (view View) html() string {
    // println(view.layout)
    return $tmpl('./templates/view.html')
}

// fn model_web_example() View {
//     example_main:=$tmpl("templates/example_main.md")
//     example_nav:=$tmpl("templates/example_nav.md")

//     navbar := Navbar{
//         brand: NavItem{href: '#', text: 'MyWebsite', class_name: 'brand'},
//         items: [
//             NavItem{href: '#home', text: 'Home'},
//             NavItem{href: '#about', text: 'About'},
//             NavItem{href: '#services', text: 'Services'},
//             NavItem{href: '#contact', text: 'Contact'}
//         ]
//     }

//     markdown_content := MarkdownContent{nav: example_nav, content: example_main, title: 'MyView'}

//     return View{navbar: navbar, markdown: markdown_content, title: 'An Example Index Page'}
// }
