extends PanelContainer

const ScoreEntryScene = preload("uid://cep7vbmgdtwhh")

@onready var best_score_label: Label = %BestScoreLabel
@onready var no_scores: Control = %NoScores
@onready var score_list: Container = %ScoreList


func _ready() -> void:
	refresh()


func refresh() -> void:
	var highscores = Config.load_highscores()
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


func _on_clear_button_pressed():
	"""Clear all highscores"""
	var file = FileAccess.open("highscores.json", FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify({"scores": []}))
	file.close()
	print("🗑️ Cleared all highscores")

	refresh()
