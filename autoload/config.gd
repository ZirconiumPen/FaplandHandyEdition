extends Node

const PATH_TO_HIGHSCORES = "highscores.json"


func save_highscore(round_reached: int, reason: String, start_time: float) -> void:
	"""Save the highscore with timestamp"""
	var timestamp = Time.get_datetime_string_from_system(true)
	var session_time = Time.get_unix_time_from_system() - start_time

	# Load existing highscores
	var highscores = load_highscores()

	# Add new entry
	var new_entry = {
		"round": round_reached,
		"reason": reason,
		"timestamp": timestamp,
		"session_time": session_time
	}

	highscores.append(new_entry)

	# Sort by round (highest first)
	highscores.sort_custom(func(a, b): return a["round"] > b["round"])

	# Keep only top 10
	if highscores.size() > 10:
		highscores = highscores.slice(0, 10)

	# Save to file
	var file = FileAccess.open("highscores.json", FileAccess.WRITE)
	if not file:
		print("❌ Could not save highscore file")
		return
	file.store_string(JSON.stringify({"scores": highscores}))
	file.close()
	print("💾 Saved highscore: Round %s (%s)" % [round_reached, reason])


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
	if not data.has("scores"):
		return []

	return data["scores"]
