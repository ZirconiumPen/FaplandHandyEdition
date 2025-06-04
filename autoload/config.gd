extends Node

const PATH_TO_HIGHSCORES = "highscores.json"


func load_highscores() -> Array:
	if not FileAccess.file_exists(PATH_TO_HIGHSCORES):
		return []

	var file = FileAccess.open(PATH_TO_HIGHSCORES, FileAccess.READ)
	if not file:
		return []

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		return []

	var data = json.data
	if data.has("scores"):
		return data["scores"]
	else:
		return []
