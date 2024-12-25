#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.openai
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
import os

console.print_header('OPENAI Example.')

// Check for required environment variables
key := os.getenv('OPENAIKEY')
if key == '' {
	eprintln('Error: OPENAIKEY environment variable is not set')
	eprintln('Please set it using: export OPENAIKEY=your-yourkey')
	exit(1)
}

heroscript := "
!!openai.configure
    name:'default'
    openaikey:'${key}'
"

openai.play(heroscript: heroscript)!

mut ai_cli := openai.get()!

mut msg := []openai.Message{}
msg << openai.Message{
	role:    openai.RoleType.user
	content: 'Say this is a test!'
}
mut msgs := openai.Messages{
	messages: msg
}
res := ai_cli.chat_completion(openai.ModelType.gpt_3_5_turbo, msgs)!
print(res)

models := ai_cli.list_models()!

model := ai_cli.get_model(models.data[0].id)!
print(model)
images_created := ai_cli.create_image(openai.ImageCreateArgs{
	prompt:     'Calm weather'
	num_images: 2
	size:       openai.ImageSize.size_512_512
	format:     openai.ImageRespType.url
})!
print(images_created)
images_updated := ai_cli.create_edit_image(openai.ImageEditArgs{
	image_path: '/path/to/image.png'
	mask_path:  '/path/to/mask.png'
	prompt:     'Calm weather'
	num_images: 2
	size:       openai.ImageSize.size_512_512
	format:     openai.ImageRespType.url
})!
print(images_updated)
images_variatons := ai_cli.create_variation_image(openai.ImageVariationArgs{
	image_path: '/path/to/image.png'
	num_images: 2
	size:       openai.ImageSize.size_512_512
	format:     openai.ImageRespType.url
})!
print(images_variatons)

transcription := ai_cli.create_transcription(openai.AudioArgs{
	filepath: '/path/to/audio'
})!
print(transcription)

translation := ai_cli.create_tranlation(openai.AudioArgs{
	filepath: '/path/to/audio'
})!
print(translation)

file_upload := ai_cli.upload_file(filepath: '/path/to/file.jsonl', purpose: 'fine-tune')
print(file_upload)
files := ai_cli.list_filess()!
print(files)
resp := ai_cli.create_fine_tune(training_file: file.id, model: 'curie')!
print(resp)

fine_tunes := ai_cli.list_fine_tunes()!
print(fine_tunes)

fine_tune := ai_cli.get_fine_tune(fine_tunes.data[0].id)!
print(fine_tune)

moderations := ai_cli.create_moderation('Something violent', openai.ModerationModel.text_moderation_latest)!
print(moderations)

embeddings := ai_cli.create_embeddings(
	input: ['sample embedding input']
	model: openai.EmbeddingModel.text_embedding_ada
)!
print(embeddings)
