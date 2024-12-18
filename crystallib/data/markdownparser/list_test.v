module markdownparser

import freeflowuniverse.crystallib.data.markdownparser.elements

const text = '
# Farmerbot

Welcome to the farmerbot. 
### Content: 
- [Introduction](introduction.md)
- [About us](aboutus.md)
  - [Our Goals & Strategy](mission.md)
  - [What we have done so far](sofar.md)
  - [Our team](team.md)
- [About Dams](aboutdams.md)
  - [The Hydro Dam Gold Rush](damgoldrush.md)
3. [About Rivers](aboutrivers.md)
7. [Dams in the Balkans](damsbalkans.md)
  - [Why the Balkans?](whybalkans.md)
  - [Community Uprising against the Dams in the Balkans](community.md)
  - [Why Montenegro?](whymontenegro.md)
  - [Case Study: Komarnica Dam](komarnicadam.md)
  - [Current Hydro Dam Mitigation Challenges](mitigation.md)
  - test
  - [Climate Vulnerability](climatevulnerability.md)
   - 1,2,3 and 4 whitespaces have the same indentation, so this line should have the same indentation as the previous line
    - this has the same indentation as the previous one 
     - this is at an indentation level deeper than the previous one
7. should be ordered
this text is not part of the list
  2. first ordered list item
  3. second...hamada. orderd list items


hamada'

fn test_wiki_headers_paragraphs() {
	mut docs := new(content: text)!

	assert docs.children.len == 9
	assert docs.children[0] is elements.Paragraph
	assert docs.children[1] is elements.Header
	assert docs.children[2] is elements.Paragraph
	assert docs.children[3] is elements.Header
	assert docs.children[4] is elements.Paragraph
	assert docs.children[5] is elements.List
	assert docs.children[6] is elements.Paragraph
	assert docs.children[7] is elements.List
	assert docs.children[8] is elements.Paragraph
}

fn test_deterministic_output() {
	mut doc1 := new(content: text)!
	md1 := doc1.markdown()!

	mut doc2 := new(content: md1)!
	md2 := doc2.markdown()!

	assert md1 == md2
}

fn test_simple_list() {
	content := '
- li1
- li2'
	mut doc1 := new(content: content)!

	assert doc1.children.len == 2

	assert doc1.children[0] is elements.Paragraph
	assert doc1.children[1] is elements.List

	list := doc1.children[1]
	assert list.children.len == 2

	list_item1 := list.children[0]
	assert list_item1 is elements.ListItem
	assert list_item1.content == '- li1'

	list_item2 := list.children[1]
	assert list_item2 is elements.ListItem
	assert list_item2.content == '- li2'
}

fn test_nested_list() {
	content := '
- li1
  1. li2
  2. li3'

	mut doc := new(content: content)!

	assert doc.children.len == 2
	assert doc.children[0] is elements.Paragraph
	assert doc.children[1] is elements.List

	list := doc.children[1]
	assert list.children.len == 3

	li1 := list.children[0]
	assert li1 is elements.ListItem
	assert li1.content == '- li1'

	li2 := list.children[1]
	assert li2 is elements.ListItem
	assert li2.content == '  1. li2'

	li3 := list.children[2]
	assert li3 is elements.ListItem
	assert li3.content == '  2. li3'
}
