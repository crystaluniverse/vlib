module components

import freeflowuniverse.crystallib.data.markdownparser
import freeflowuniverse.crystallib.web.auth.authentication.email {StatelessAuthenticator}
import veb

pub struct MarkdownContent {
pub mut:
    nav string
    content string
    title string
}

pub interface IComponent {
    html() string
}
