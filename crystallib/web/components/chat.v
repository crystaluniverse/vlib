module components

pub struct Chat {
pub:
	messages []Message
}

pub struct Message {
pub:
    timestamp string
    sender    string
    content   string
}

pub fn (chat Chat) html() string {
    return $tmpl('./templates/chat.html')
}