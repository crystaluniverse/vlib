module components

import net.html

// Define HTML element structs implementing the IComponent interface
struct Anchor {
    href string
    text string
}

struct Paragraph {
    content string
}

struct ListItem {
    children []IComponent
}

struct UnorderedList {
    children []IComponent
}

// Implement html() for Anchor
fn (a Anchor) html() string {
    return '<a href="${a.href}">${a.text}</a>'
}

// Implement html() for Paragraph
fn (p Paragraph) html() string {
    return '<p>${p.content}</p>'
}

// Implement html() for ListItem
fn (li ListItem) html() string {
    mut result := '<li>'
    for child in li.children {
        result += child.html() // Call the html() method of each child
    }
    result += '</li>'
    return result
}

// Implement html() for UnorderedList
fn (ul UnorderedList) html() string {
    mut result := '<ul>'
    for child in ul.children {
        result += child.html() // Call the html() method of each child
    }
    result += '</ul>'
    return result
}

// Recursive parse function that processes any HTML tag and its children
fn parse_html_tag(tag &html.Tag) !IComponent {
    match tag.name {
        'ul' {
            mut children := []IComponent{}
            for child_tag in tag.children {
                if child_tag.name == 'li' {
                    list_item := parse_html_tag(child_tag)!
                    children << list_item
                }
            }
            return UnorderedList{
                children: children
            }
        }
        'li' {
            mut children := []IComponent{}
            for child_tag in tag.children {
                child_element := parse_html_tag(child_tag)!
                children << child_element
            }
            return ListItem{
                children: children
            }
        }
        'a' {
            return Anchor{
                href: tag.attributes['href'] or { '' },
                text: tag.content
            }
        }
        'p' {
            mut children := []IComponent{}
            for child_tag in tag.children {
                child_element := parse_html_tag(child_tag)!
                children << child_element
            }
            return ListItem{
                children: children
            }
        }
        else {
            // For any unknown tag, treat it as a simple element
            return Paragraph{
                content: tag.content
            }
        }
    }
}

// Function to parse the root HTML string
fn parse_html(html_str string) ![]IComponent {
    mut components := []IComponent{}

    doc := html.parse(html_str)
    
    for tag in doc.get_tags() {
        components << parse_html_tag(tag)!
    }
    
    return components
}