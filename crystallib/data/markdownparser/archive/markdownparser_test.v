module markdownparser

import os

const testpath = os.dir(@FILE) + '/testdata'

// fn test_parsing_using_path() {
// 	mut doc := new(path: '${markdownparser.testpath}/test.md')!
// 	correct_doc := '**** Header 1: this is a test
// **** Paragraph
//     - [this is link](something.md)
//     - ![this is link2](something.jpg)

// **** Header 2: ts
// **** Paragraph
//     ![this is link2](something.jpg)'

// 	assert doc.elements[0] is Header
// 	header_item := doc.elements[0] as Header
// 	assert header_item.content == 'this is a test'
// 	assert header_item.depth == 1
// }

fn test_parsing_using_path() {
	mut doc := new(path: '${markdownparser.testpath}/test.md')!
	correct_doc := '**** Header 1: this is a test
**** Paragraph
    - [this is link](something.md)
    - ![this is link2](something.jpg)
    

**** Header 2: ts
**** Paragraph
    ![this is link2](something.jpg)'

	assert doc.elements[0] is Header
	header_item := doc.elements[0] as Header
	assert header_item.content == 'this is a test'
	assert header_item.depth == 1
}