module embedding

pub struct Embedder {
	Embedded
}

pub struct Embedded {
	id          int
	related_ids []int
	name        string
	tags        []string
	date        time.Time
}
