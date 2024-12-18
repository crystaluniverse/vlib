module sandbox

pub struct ImageSource {
pub mut:
	repository string
	release    string
}

fn (mut f Factory) init() {
	f.imagesources['ubuntu22'] = ImageSource{
		repository: 'http://de.archive.ubuntu.com/ubuntu'
		release:    'jammy'
	}

	f.imagesources['debian'] = ImageSource{
		repository: 'http://deb.debian.org/debian/'
		release:    'stable'
	}
}
