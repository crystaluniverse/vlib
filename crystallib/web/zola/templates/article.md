---
id: @{article.cid}
title: @{article.title}
image_caption: @{article.name}
description: @{article.description}
@if article.date.unix != 0
date: @{article.date.day()}
@end
taxonomies:
    people: [@{article.authors.map(it.cid).join(',')}]
    tags: [@{article.tags.join(',')}]
    news-category: [@{article.categories.join(',')}]
extra:
    imgPath: @{image_path}
---

@{content}
