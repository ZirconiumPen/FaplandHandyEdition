extends PanelContainer

const ScoreEntryScene = preload("uid://cep7vbmgdtwhh")

@onready var best_score_label: Label = %BestScoreLabel
@onready var no_scores: Control = %NoScores
@onready var score_list: Container = %ScoreList


func _ready() -> void:
	refresh()


func refresh() -> void:
	var highscores = load_highscores()
	if not highscores:
		score_list.hide()
		no_scores.show()
		best_score_label.text = "No scores yet"
		return

	best_score_label.text = "Best: Round %s" % highscores[0]["round"]

	# Scores list
	for i in range(min(6, highscores.size())):
		var score = highscores[i]
		var rank_text = (
			"%s %s. Round %s"
			% ["💀" if score["reason"] == "ejaculation" else "🏆", i + 1, score["round"]]
		)

		var score_label = ScoreEntryScene.instantiate()
		score_label.text = rank_text

		var score_color: Color
		match i:
			0:
				score_color = Color.GOLD
			1:
				score_color = Color.SILVER
			2:
				score_color = Color(0.8, 0.5, 0.2)
			_:
				score_color = Color.WHITE
		score_label.add_theme_color_override("font_color", score_color)
		score_list.add_child(score_label)


func load_highscores() -> Array:
	# TODO: util function for json
	print("Checking for highscores.json...")
	if not FileAccess.file_exists("highscores.json"):
		return []

	print("Found highscores.json, opening...")
	var file = FileAccess.open("highscores.json", FileAccess.READ)
	if not file:
		return []

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		print("JSON parse failed!")
		return []

	print("Parsed JSON: ", json.data)

	var data = json.data
	if data.has("scores"):
		return data["scores"]
	else:
		return []


func _on_clear_button_pressed():
	"""Clear all highscores"""
	var file = FileAccess.open("highscores.json", FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify({"scores": []}))
	file.close()
	print("🗑️ Cleared all highscores")

	refresh()
