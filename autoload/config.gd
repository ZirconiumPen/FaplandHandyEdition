extends Node

const PATH_TO_HIGHSCORES = "highscores.json"
const PATH_TO_PAUSE = "pause_config.json"


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


func clear_pause_config() -> void:
	if not FileAccess.file_exists(PATH_TO_PAUSE):
		print("📁 No pause config file found to clear")
		return
	var file = FileAccess.open(PATH_TO_PAUSE, FileAccess.WRITE)
	if not file:
		print("❌ Could not clear pause config file")
		return

	# Write empty entries array
	var empty_config = {"entries": []}
	file.store_string(JSON.stringify(empty_config))
	file.close()
	print("🧹 Cleared pause config file on startup")


func save_pause_config_timestamped(max_pauses_val: int, reason: String, pause_time: int):
	"""Save pause config with timestamp and writer info"""
	var timestamp = Time.get_datetime_string_from_system(true) + "Z"

	# Read existing data
	var pause_data = {"entries": []}
	if FileAccess.file_exists(PATH_TO_PAUSE):
		var in_file = FileAccess.open(PATH_TO_PAUSE, FileAccess.READ)
		if in_file:
			var json_text = in_file.get_as_text()
			in_file.close()

			var json = JSON.new()
			if json.parse(json_text) == OK:
				pause_data = json.data

	# Ensure entries array exists
	if not pause_data.has("entries"):
		pause_data["entries"] = []

	# Add new entry
	var new_entry = {
		"timestamp": timestamp,
		"max_pauses": max_pauses_val,
		"pause_duration": pause_time,
		"writer": "godot",
		"reason": reason
	}

	pause_data["entries"].append(new_entry)

	# Keep only last 50 entries
	if pause_data["entries"].size() > 50:
		pause_data["entries"] = pause_data["entries"].slice(-50)

	# Write back to file
	var file = FileAccess.open(PATH_TO_PAUSE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(pause_data))
		file.close()

	print("💾 Saved pause config entry: %s" % new_entry)


func load_pause_config_timestamped() -> int:
	"""Load the latest pause config from timestamped entries"""
	if not FileAccess.file_exists(PATH_TO_PAUSE):
		print("⚠️ No pause config file found, using default")
		return 1

	var file = FileAccess.open(PATH_TO_PAUSE, FileAccess.READ)
	if not file:
		print("❌ Could not open pause config file")
		return 1

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		print("❌ Could not parse pause config JSON")
		return 1

	var pause_data = json.data

	if not pause_data.has("entries") or pause_data["entries"].size() == 0:
		print("⚠️ No entries found in pause config")
		return 1

	# Find the most recent entry
	var latest_entry = null
	var latest_timestamp = ""

	for entry in pause_data["entries"]:
		if entry["timestamp"] > latest_timestamp:
			latest_timestamp = entry["timestamp"]
			latest_entry = entry

	if not latest_entry:
		print("❌ Could not find latest entry")
		return 1

	print("🔍 DEBUG: Found ", pause_data["entries"].size(), " entries in pause config")
	print("🔍 DEBUG: Latest entry: %s" % latest_entry)

	# Log the full history for debugging
	print("📜 PAUSE CONFIG HISTORY:")
	var entries_sorted = pause_data["entries"].duplicate()
	entries_sorted.sort_custom(func(a, b): return a["timestamp"] < b["timestamp"])

	for i in range(entries_sorted.size()):
		var entry = entries_sorted[i]
		print(
			(
				"  %s. {timestamp} | {writer} | pauses={max_pauses} | reason={reason}".format(entry)
				% (i + 1)
			)
		)

	return int(latest_entry["max_pauses"])
