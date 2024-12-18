# www.threefold.io development script

We first define our website and add a zola template for it

```js
!!website.define name:'website' title:'Threefold Development' 

!!website.template_add url:'https://github.com/threefoldfoundation/www_threefold_io/tree/development_zola'
```

Then we add the doctree's we will use for the website.
We use `threefoldfoundation/threefold_data` for blogs, people and news. We use `threefoldfoundation/www_threefold_io` for site content for pages.

```js
!!website.doctree_add url:'https://github.com/freeflowuniverse/crystallib/tree/development_zola/examples/webtools/zola/website/content'

add collections to the website
!!website.doctree_add url:'https://github.com/threefoldfoundation/threefold_data/tree/development_zola/content'
```

Next, we add a header and a footer for our website

```js
!!website.header_add

!!website.header_link_add
    label: 'About'
    page: 'about'

!!website.header_link_add
    label: 'How it works'
    page: 'how'

!!website.header_link_add
    label: 'Farm'
    page: 'farm'

!!website.header_link_add
    label: 'Deploy'
    page: 'deploy'

!!website.header_link_add
    label: 'Newsroom'
    page: 'newsroom'

!!website.header_link_add
    label: 'Blog'
    page: 'blog'

!!website.header_link_add
    label: 'Community'
    page: 'community'

!!website.header_link_add
    label: 'People'
    page: 'people'
```

```js
!!website.footer_add 
    collection: 'content'
    file: 'footer.md'
```

Let's then add our pages

```js
!!website.page_add 
    name: 'Home'
    collection: 'content'
    file: 'home.md'
    homepage: true

!!website.page_add
    name: 'About'
    collection: 'content'
    file: 'about.md'
```

Finally we can select and add some blog posts, news and people sections.

## Blogs

Below we select blogs relavant to threefold.io from our data repository

```js
!!website.blog_add 
    name: 'A better understanding of wealth'
    collection: 'blog'
    file: 'a_better_understanding_of_wealth.md'
    image: 'a_better_understanding_of_wealth.jpg'
```

## People

```js
!!website.person_add 
    name: 'Adnan Fatayerji'
    collection: 'person'
    file: 'adnan_fatayerji.md'

!!website.person_add 
    name: 'Alexandre Hannelas'
    collection: 'person'
    file: 'alexandre_hannelas.md'
```

## News

```js
!!website.news_add 
    name: '3Bot Connect & TFConnect'
    collection: 'news'
    file: '3bot_connect_tf_connect.md'

```

```js
!!website.generate
```