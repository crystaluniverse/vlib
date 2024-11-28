module components

pub struct Feed {
	pub:
    feed []Post
}

pub struct Post {
	pub:
    timestamp  string
    user       string
    typ       string @[json: 'type'] // Can be "text", "news", or "image"
    content    string
    description string = "" // Only for image posts, optional
}

pub fn (feed Feed) html() string {
	return $tmpl('./templates/feed.html')
}