#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.openai as op

mut ai_cli := op.new()!
mut msg := []op.Message{}
msg << op.Message{
	role:    op.RoleType.user
	content: 'Say this is a test!'
}
mut msgs := op.Messages{
	messages: msg
}
res := ai_cli.chat_completion(op.ModelType.gpt_3_5_turbo, msgs)!
print(res)

models := ai_cli.list_models()!

model := ai_cli.get_model(models.data[0].id)!
print(model)
images_created := ai_cli.create_image(op.ImageCreateArgs{
	prompt:     'Calm weather'
	num_images: 2
	size:       op.ImageSize.size_512_512
	format:     op.ImageRespType.url
})!
print(images_created)
images_updated := ai_cli.create_edit_image(op.ImageEditArgs{
	image_path: '/path/to/image.png'
	mask_path:  '/path/to/mask.png'
	prompt:     'Calm weather'
	num_images: 2
	size:       op.ImageSize.size_512_512
	format:     op.ImageRespType.url
})!
print(images_updated)
images_variatons := ai_cli.create_variation_image(op.ImageVariationArgs{
	image_path: '/path/to/image.png'
	num_images: 2
	size:       op.ImageSize.size_512_512
	format:     op.ImageRespType.url
})!
print(images_variatons)

transcription := ai_cli.create_transcription(op.AudioArgs{
	filepath: '/path/to/audio'
})!
print(transcription)

translation := ai_cli.create_tranlation(op.AudioArgs{
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

moderations := ai_cli.create_moderation('Something violent', op.ModerationModel.text_moderation_latest)!
print(moderations)

embeddings := ai_cli.create_embeddings(
	input: ['sample embedding input']
	model: op.EmbeddingModel.text_embedding_ada
)!
print(embeddings)
