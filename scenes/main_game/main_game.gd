class_name MainGame
extends Control

@export var countdown_time: float = 30.0

# Game State Variables
var current_round = 1
var previous_round = 1
var max_rounds = 100
# Perk System
var perk_system: PerkSystem

var dice_min = 1
var dice_max = 6
var pause_count = 1
var pause_time = 5

var is_playing = false
var is_paused = false
var game_active = true
var video_process_id = -1

# Session Timer Variables
var session_start_time: float = 0.0
var session_elapsed_time: float = 0.0

var countdown_time_left: float = countdown_time:
	set(value):
		countdown_time_left = value
		if not is_instance_valid(countdown_label):
			return
		countdown_label.text = "Click PLAY in: %ss" % int(countdown_time_left)
		if countdown_time_left <= 10:
			countdown_label.add_theme_color_override("font_color", Color.RED)
		elif countdown_time_left <= 20:
			countdown_label.add_theme_color_override("font_color", Color.YELLOW)

# Animation variables
var dice_rolling = false

@onready var water_progress_container: Panel = %WaterProgressContainer
@onready var dice_range_label: Label = %DiceRangeLabel
@onready var perk_label: Label = %PerkLabel
@onready var active_perks: Label = %ActivePerks
@onready var pause_count_label: Label = %PauseCountLabel
@onready var round_label: Label = %RoundLabel
@onready var play_button: Button = %PlayButton
@onready var roll_button: Button = %RollButton
@onready var dice_result: Label = %DiceResult
@onready var timer_label: Label = %TimerLabel
@onready var coming_up_box: Panel = %ComingUpBox
@onready var countdown_label: Label = %CountdownLabel
@onready var countdown_timer: Timer = $CountdownTimer


func update_pause_count_from_file():
	"""Read back the updated pause count from the Python script"""

	var current_pauses = load_pause_config_timestamped()

	pause_count = current_pauses + 1  # Apply the +1 stacking bonus
	print("📝 Pauses set to: %s (%s + 1 bonus)" % [pause_count, current_pauses])


func _ready():
	print("🎮 Creating AAA Quality FapLand UI with Session Timer...")

	if FileAccess.file_exists("pause_config.json"):
		var file = FileAccess.open("pause_config.json", FileAccess.WRITE)
		if file:
			# Write empty entries array
			var empty_config = {"entries": []}
			file.store_string(JSON.stringify(empty_config))
			file.close()
			print("🧹 Cleared pause config file on startup")
		else:
			print("❌ Could not clear pause config file")
	else:
		print("📁 No pause config file found to clear")

	# Initialize session timer
	var current_time = Time.get_time_dict_from_system()
	session_start_time = (
		current_time["hour"] * 3600 + current_time["minute"] * 60 + current_time["second"]
	)

	# Initialize perk system
	perk_system = PerkSystem.new(self)
	perk_system.perk_earned.connect(_on_perk_earned)
	perk_system.perk_used.connect(_on_perk_used)
	perk_system.ui_update_needed.connect(update_all_ui_animated)

	#clear_ui()
	start_round(current_round)

	# Start session timer updates
	coming_up_box.open(current_round)
	#create_animated_sprite_rect()

	print("✅ AAA Quality UI ready with session tracking!")


func _on_session_timer_timeout() -> void:
	"""Update session elapsed time and UI display"""
	var current_time = Time.get_time_dict_from_system()
	var current_seconds = (
		current_time["hour"] * 3600 + current_time["minute"] * 60 + current_time["second"]
	)
	session_elapsed_time = current_seconds - session_start_time

	# Handle day rollover
	if session_elapsed_time < 0:
		session_elapsed_time += 86400  # 24 hours in seconds

	update_session_timer_display()


func update_session_timer_display():
	"""Update the session timer display with premium formatting"""
	@warning_ignore("INTEGER_DIVISION")
	var hours = int(session_elapsed_time) / 3600
	@warning_ignore("INTEGER_DIVISION")
	var minutes = (int(session_elapsed_time) % 3600) / 60
	var seconds = int(session_elapsed_time) % 60

	var time_text = ""
	if hours > 0:
		time_text = "Session: %02d:%02d:%02d" % [hours, minutes, seconds]
	else:
		time_text = "Session: %02d:%02d" % [minutes, seconds]

	timer_label.text = time_text


func clear_ui():
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame


func create_checkpoint_marker(parent: Control, checkpoint: Dictionary):
	# Checkpoint container
	var checkpoint_container = Panel.new()
	checkpoint_container.position = checkpoint.pos
	checkpoint_container.size = Vector2(120, 80)

	# Premium checkpoint styling
	var checkpoint_style = StyleBoxFlat.new()
	checkpoint_style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	checkpoint_style.border_width_left = 2
	checkpoint_style.border_width_right = 2
	checkpoint_style.border_width_top = 2
	checkpoint_style.border_width_bottom = 2
	checkpoint_style.border_color = checkpoint.color
	checkpoint_style.corner_radius_top_left = 15
	checkpoint_style.corner_radius_top_right = 15
	checkpoint_style.corner_radius_bottom_left = 15
	checkpoint_style.corner_radius_bottom_right = 15
	checkpoint_style.shadow_color = Color(
		checkpoint.color.r, checkpoint.color.g, checkpoint.color.b, 0.3
	)
	checkpoint_style.shadow_size = 6
	checkpoint_container.add_theme_stylebox_override("panel", checkpoint_style)
	parent.add_child(checkpoint_container)

	# Flag icon
	var flag_label = Label.new()
	flag_label.text = checkpoint.flag
	flag_label.position = Vector2(10, 5)
	flag_label.size = Vector2(40, 30)
	flag_label.add_theme_font_size_override("font_size", 24)
	flag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	checkpoint_container.add_child(flag_label)

	# Checkpoint text
	var checkpoint_label = Label.new()
	checkpoint_label.text = checkpoint.text
	checkpoint_label.position = Vector2(0, 35)
	checkpoint_label.size = Vector2(120, 25)
	checkpoint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checkpoint_label.add_theme_font_size_override("font_size", 12)
	checkpoint_label.add_theme_color_override("font_color", checkpoint.color)
	checkpoint_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	checkpoint_label.add_theme_constant_override("shadow_outline_size", 2)
	checkpoint_container.add_child(checkpoint_label)

	# Progress indicator (if reached)
	if current_round >= checkpoint.progress:
		var checkmark = Label.new()
		checkmark.text = "✓"
		checkmark.position = Vector2(85, 5)
		checkmark.size = Vector2(30, 30)
		checkmark.add_theme_font_size_override("font_size", 20)
		checkmark.add_theme_color_override("font_color", Color.GREEN)
		checkmark.add_theme_color_override("font_shadow_color", Color.BLACK)
		checkmark.add_theme_constant_override("shadow_outline_size", 2)
		checkmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		checkmark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		checkpoint_container.add_child(checkmark)

	# Checkpoint pulse animation
	var checkpoint_tween = create_tween()
	checkpoint_tween.set_loops()
	checkpoint_tween.tween_property(
		checkpoint_container, "modulate", Color(1.2, 1.2, 1.2, 1.0), 1.5
	)
	checkpoint_tween.tween_property(checkpoint_container, "modulate", Color.WHITE, 1.5)


func save_pause_config_timestamped(max_pauses_val: int, reason: String):
	"""Save pause config with timestamp and writer info"""
	var timestamp = Time.get_datetime_string_from_system(true) + "Z"

	# Read existing data
	var pause_data = {"entries": []}
	if FileAccess.file_exists("pause_config.json"):
		var in_file = FileAccess.open("pause_config.json", FileAccess.READ)
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
	var file = FileAccess.open("pause_config.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(pause_data))
		file.close()

	print("💾 Saved pause config entry: %s" % new_entry)


func load_pause_config_timestamped() -> int:
	"""Load the latest pause config from timestamped entries"""
	if not FileAccess.file_exists("pause_config.json"):
		print("⚠️ No pause config file found, using default")
		return 1

	var file = FileAccess.open("pause_config.json", FileAccess.READ)
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

	if latest_entry:
		print("🔍 DEBUG: Found ", pause_data["entries"].size(), " entries in pause config")
		print("🔍 DEBUG: Latest entry: %s" % latest_entry)

		# Log the full history for debugging
		print("📜 PAUSE CONFIG HISTORY:")
		var entries_sorted = pause_data["entries"].duplicate()
		entries_sorted.sort_custom(func(a, b): return a["timestamp"] < b["timestamp"])

		for i in range(entries_sorted.size()):
			var entry = entries_sorted[i]
			print(
				"  ",
				i + 1,
				". ",
				entry["timestamp"],
				" | ",
				entry["writer"],
				" | pauses=",
				entry["max_pauses"],
				" | reason=",
				entry.get("reason", "unknown")
			)

		return int(latest_entry["max_pauses"])
	else:
		print("❌ Could not find latest entry")
		return 1


func start_round(round_num: int):
	if round_num > max_rounds:
		current_round = max_rounds
		round_num = max_rounds

	current_round = round_num
	is_playing = false

	play_button.disabled = false
	play_button.text = "▶ PLAY"

	var button_tween := create_tween()
	button_tween.set_loops()
	button_tween.tween_property(play_button, "modulate", Color(1.3, 1.3, 1.3), 1.2)
	button_tween.tween_property(play_button, "modulate", Color.WHITE, 1.2)

	roll_button.disabled = true

	update_all_ui_animated()
	print("🎯 Round %s ready - Pauses: %s/1" % [current_round, pause_count])
	show_aaa_popup(
		(
			"🎮 Round %s ready! You have %s pause%s available."
			% [current_round, pause_count, "" if pause_count == 1 else "s"]
		),
		Color.CYAN
	)


func _on_play_button_pressed():
	remove_countdown_timer()
	if not game_active:
		return

	previous_round = current_round

	print("🎬 PLAY PRESSED - Starting Round %s" % current_round)
	coming_up_box.close()

	# Premium button state changes with animation
	play_button.disabled = true
	play_button.text = "🎬 PLAYING..."

	# Premium button press animation
	var press_tween = create_tween()
	press_tween.tween_property(play_button, "scale", 0.92 * Vector2.ONE, 0.1)
	press_tween.tween_property(play_button, "scale", Vector2.ONE, 0.15)
	press_tween.tween_property(play_button, "modulate", Color(0.6, 0.6, 0.6), 0.3)

	roll_button.disabled = true

	is_playing = true

	# Launch Python VLC script with handy sync
	launch_video_with_handy_sync()

	# Start monitoring for video completion
	monitor_video_completion()


func launch_video_with_handy_sync():
	save_pause_config_timestamped(pause_count, "round_start")

	var video_name = str(current_round)
	var python_script = "scripts/sync_handy.py"

	print("🚀 Launching Python script: %s with video: %s" % [python_script, video_name])

	# Check if files exist before launching
	var video_path = "media/%s.mp4" % video_name
	var funscript_path = "media/%s.funscript" % video_name

	if not FileAccess.file_exists(video_path):
		print("❌ ERROR: Video file not found: %s" % video_path)
		show_aaa_popup("❌ ERROR: Video file %s.mp4 not found!" % video_name, Color.RED)
		reset_play_button()
		return

	if not FileAccess.file_exists(funscript_path):
		print("❌ ERROR: Funscript file not found: %s" % funscript_path)
		show_aaa_popup("❌ ERROR: Funscript file %s.funscript not found!" % video_name, Color.RED)
		reset_play_button()
		return

	if not FileAccess.file_exists(python_script):
		print("❌ ERROR: Python script not found: %s" % python_script)
		show_aaa_popup("❌ ERROR: Script file %s not found!" % python_script, Color.RED)
		reset_play_button()
		return

	print("✅ All files found, launching Python script...")

	# Try different Python commands
	var python_commands = ["python", "python3", "py"]
	var process_id = -1

	for python_cmd in python_commands:
		print("🐍 Trying Python command: %s" % python_cmd)
		var args = [python_script, video_name]
		process_id = OS.create_process(python_cmd, args)

		if process_id > 0:
			print("✅ Success with %s" % python_cmd)
			break
		else:
			print("❌ Failed with %s" % python_cmd)

	if process_id > 0:
		video_process_id = process_id
		print("✅ Python VLC+Handy script started with PID: %s" % video_process_id)
		show_aaa_popup(
			(
				"🎬 VLC Player launched in FULLSCREEN! Pauses: %s (%ss each)"
				% [pause_count, pause_time]
			),
			Color.GREEN
		)
	else:
		print("❌ Failed to start Python script with any Python command")
		show_aaa_popup(
			"❌ ERROR: Could not launch Python script! Make sure Python is installed.", Color.RED
		)
		reset_play_button()


func monitor_video_completion():
	print("👀 Starting video completion monitor...")

	var monitor_attempts = 0
	var max_attempts = 600

	while video_process_id > 0 and is_playing and game_active and monitor_attempts < max_attempts:
		await get_tree().create_timer(2.0).timeout
		monitor_attempts += 1

		# Try to check if process is still alive
		if OS.has_method("is_process_running"):
			var process_still_running = OS.is_process_running(video_process_id)
			if not process_still_running:
				print("🎬 Video script finished! (Auto-detected)")

				# Check for ejaculation file
				if FileAccess.file_exists("iejaculated.txt"):
					print("💀 Ejaculation file found - GAME OVER!")
					handle_ejaculation_from_video()
					return
				else:
					print("✅ Normal video completion")
					on_video_completed()
					break

		if monitor_attempts % 15 == 0:
			print("⏳ Video still playing... Click 'Video Finished' when done.")

	if monitor_attempts >= max_attempts:
		print("⏰ Monitor timeout - assuming video finished")
		on_video_completed()


func handle_ejaculation_from_video():
	print("💀 EJACULATION DETECTED FROM VIDEO!")

	save_highscore(current_round, "ejaculation")

	# Clean up ejaculation file
	if FileAccess.file_exists("iejaculated.txt"):
		var file = FileAccess.open("iejaculated.txt", FileAccess.READ)
		if file:
			file.close()
		OS.move_to_trash(ProjectSettings.globalize_path("iejaculated.txt"))
		print("🗑️ Cleaned up ejaculation signal file")

	# Kill the video process
	if video_process_id > 0:
		OS.kill(video_process_id)
		print("🛑 Killed video process")

	# Show premium game over popup
	show_aaa_game_over_popup()

	# Disable all game controls
	game_active = false
	play_button.disabled = true
	roll_button.disabled = true

	await get_tree().create_timer(3.0).timeout
	print("👋 Returning to start menu...")
	get_tree().change_scene_to_file("res://scenes/startup.tscn")


func on_video_completed():
	update_pause_count_from_file()
	perk_system.update_perk_timers()

	print("✅ Video completed for Round %s" % current_round)
	if current_round == max_rounds:
		victory()
		return
	perk_system.check_perk_rewards(current_round)

	is_playing = false

	# Premium button state changes with animation
	roll_button.disabled = false

	var activate_tween := create_tween()
	activate_tween.tween_property(roll_button, "modulate", Color.WHITE, 0.4)
	activate_tween.tween_property(roll_button, "scale", 1.08 * Vector2.ONE, 0.3)
	activate_tween.tween_property(roll_button, "scale", Vector2.ONE, 0.3)

	var glow_tween := create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(roll_button, "modulate", Color(1.3, 1.3, 1.3), 1.2)
	glow_tween.tween_property(roll_button, "modulate", Color.WHITE, 1.2)

	play_button.text = "▶ PLAY"
	play_button.modulate = Color(0.6, 0.6, 0.6, 1.0)

	show_aaa_popup("🎬 Video finished! Roll the dice to continue.", Color.YELLOW)
	video_process_id = -1


func reset_play_button():
	play_button.disabled = false
	play_button.text = "▶ PLAY"
	play_button.modulate = Color.WHITE
	is_playing = false
	video_process_id = -1


func start_play_countdown_timer():
	"""Start 30-second countdown timer for clicking play button"""
	countdown_time_left = countdown_time
	countdown_label.show()
	countdown_timer.start()


func _on_countdown_timer_timeout():
	"""Update countdown timer display"""
	countdown_time_left -= countdown_timer.wait_time
	if countdown_time_left > 0:
		return
	# Time's up - penalize player
	print("countdown expired, applying penalty")
	remove_countdown_timer()

	# Move player back rounds as penalty
	var penalty_rounds = 5
	current_round = max(1, current_round - penalty_rounds)
	show_aaa_popup("⏰ TIME'S UP! Penalty: -%s rounds!" % penalty_rounds, Color.RED)
	update_all_ui_animated()


func remove_countdown_timer():
	countdown_label.hide()
	countdown_timer.stop()


func _on_perk_earned(_perk_id: String):
	"""Handle perk earned signal"""
	make_perk_label_clickable()


func _on_perk_used(perk_id: String):
	"""Handle perk used signal"""
	print("🎯 Perk used in main game: %s" % perk_id)


func make_perk_label_clickable():
	"""Make the perk label clickable"""

	# Disconnect existing signals
	if perk_label.gui_input.is_connected(_on_perk_label_clicked):
		perk_label.gui_input.disconnect(_on_perk_label_clicked)

	# Connect input signal
	perk_label.gui_input.connect(_on_perk_label_clicked)
	perk_label.mouse_filter = Control.MOUSE_FILTER_PASS


func _on_perk_label_clicked(event: InputEvent):
	"""Handle perk label clicks"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if perk_system.perks_inventory.size() > 0:
			perk_system.show_perk_selection_popup()
		else:
			show_aaa_popup("No perks available!", Color.GRAY)


func _on_roll_button_pressed():
	if not game_active or is_playing or dice_rolling:
		return

	print("🎲 ROLL PRESSED")
	dice_rolling = true
	var roll
	var next_round
	# Check for lucky 7 perk
	if perk_system.has_active_perk("lucky_7"):
		roll = 7
		perk_system.consume_active_perk("lucky_7")
		show_aaa_popup("🍀 Lucky 7 activated! Rolled: 7", Color.GOLD)
		next_round = current_round + roll
	else:
		# Disable roll button and start premium animation
		roll_button.disabled = true
		roll_button.text = "🎲 ROLLING..."

		# Premium dice roll animation
		await animate_dice_roll()

		# Roll dice and calculate next round
		roll = randi_range(dice_min, dice_max)
		next_round = current_round + roll

		print("🎲 Rolled: ", roll, " | Next Round: ", next_round)

	# Show dice result with premium animation
	dice_result.text = "Rolled: %s" % roll
	var result_tween := create_tween()
	result_tween.tween_property(dice_result, "scale", 1.4 * Vector2.ONE, 0.4)
	result_tween.tween_property(dice_result, "scale", Vector2.ONE, 0.4)
	result_tween.tween_property(dice_result, "modulate", Color.TRANSPARENT, 2.5)

	if next_round >= max_rounds:
		show_aaa_popup("🎲 Rolled %s! Moving to FINAL ROUND" % roll, Color.GOLD)
	else:
		show_aaa_popup("🎲 Rolled %s! Moving to round %s" % [roll, next_round], Color.GOLD)
	next_round = min(next_round, max_rounds)

	# Wait for animations
	await get_tree().create_timer(1.8).timeout

	# Show "Coming Up Next" display
	coming_up_box.open(next_round)

	start_play_countdown_timer()

	# Move to next round
	advance_to_round(next_round)
	dice_rolling = false


func animate_dice_roll():
	dice_result.modulate = Color.WHITE

	# Animate dice numbers rapidly with premium effects
	for i in range(20):  # More frames for smoother animation
		dice_result.text = "🎲 %s" % randi_range(1, 6)

		var bounce_tween := create_tween()
		bounce_tween.tween_property(dice_result, "scale", 1.3 * Vector2.ONE, 0.04)
		bounce_tween.tween_property(dice_result, "scale", Vector2.ONE, 0.04)

		await bounce_tween.finished


func save_highscore(round_reached: int, reason: String):
	"""Save the highscore with timestamp"""
	var timestamp = Time.get_datetime_string_from_system(true)
	var session_time = session_elapsed_time

	# Load existing highscores
	var highscores = Config.load_highscores()

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
	if file:
		file.store_string(JSON.stringify({"scores": highscores}))
		file.close()
		print("💾 Saved highscore: Round ", round_reached, " (", reason, ")")
	else:
		print("❌ Could not save highscore file")


func advance_to_round(next_round: int):
	current_round = next_round
	# Premium button state changes
	play_button.disabled = false
	play_button.text = "▶ PLAY"
	play_button.modulate = Color.WHITE

	# Re-enable premium play button glow
	var glow_tween := create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(play_button, "modulate", Color(1.3, 1.3, 1.3), 1.2)
	glow_tween.tween_property(play_button, "modulate", Color.WHITE, 1.2)

	update_all_ui_animated()
	print("🎯 Advanced to Round: %s" % current_round)
	if current_round == max_rounds:
		show_aaa_popup("🎮 FINAL ROUND - Click Play to watch video!", Color.CYAN)
	else:
		show_aaa_popup("🎮 Round %s - Click Play to watch video!" % current_round, Color.CYAN)


func get_active_perks_display_text() -> String:
	"""Get display text for active perks"""
	return perk_system.get_active_perks_display_text()


func update_all_ui_animated():
	"""Update all UI elements with premium smooth animations"""
	water_progress_container.current_round = current_round

	var scale_tween = create_tween()
	scale_tween.tween_property(round_label, "scale", 1.3 * Vector2.ONE, 0.4)
	scale_tween.tween_property(round_label, "scale", Vector2.ONE, 0.4)

	if current_round == max_rounds:
		round_label.text = "FINAL ROUND"
	else:
		round_label.text = "Round %s" % current_round

	active_perks.text = get_active_perks_display_text()
	flash_component(active_perks)

	dice_range_label.text = "🎲\nDice Range\n%s-%s" % [dice_min, dice_max]
	flash_component(dice_range_label)

	pause_count_label.text = "⏸️\nPauses Left\n%s" % pause_count
	flash_component(pause_count_label)

	# pause_time_label.text = "⏱️\nPause Duration\n%ss" % pause_time
	# flash_component(pause_time_label)

	perk_label.text = perk_system.get_perk_display_text()
	flash_component(perk_label)

	print(
		"📊 UI Updated with premium animations - Round: %s Pauses: %s" % [current_round, pause_count]
	)


func flash_component(component: CanvasItem) -> void:
	var flash_tween := create_tween()
	flash_tween.tween_property(component, "modulate", Color.GOLD, 0.3)
	flash_tween.tween_property(component, "modulate", Color.WHITE, 0.4)


func victory():
	save_highscore(100, "victory")

	show_aaa_popup("🏆 VICTORY! You reached round 100 without ejaculating!", Color.GOLD)
	print("🏆 VICTORY! Player completed the challenge!")

	# Premium victory screen
	var victory_bg = ColorRect.new()
	victory_bg.color = Color(0, 0.2, 0, 0.95)
	victory_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(victory_bg)

	# Premium victory container with glow
	var victory_container = Panel.new()
	victory_container.position = Vector2(
		get_viewport().size.x / 2 - 400, get_viewport().size.y / 2 - 150
	)
	victory_container.size = Vector2(800, 300)

	var victory_style = StyleBoxFlat.new()
	victory_style.bg_color = Color(0.05, 0.2, 0.05, 0.98)
	victory_style.border_width_left = 5
	victory_style.border_width_right = 5
	victory_style.border_width_top = 5
	victory_style.border_width_bottom = 5
	victory_style.border_color = Color.GOLD
	victory_style.corner_radius_top_left = 30
	victory_style.corner_radius_top_right = 30
	victory_style.corner_radius_bottom_left = 30
	victory_style.corner_radius_bottom_right = 30
	victory_style.shadow_color = Color(1.0, 0.8, 0.0, 0.7)
	victory_style.shadow_size = 20
	victory_container.add_theme_stylebox_override("panel", victory_style)
	add_child(victory_container)

	# Premium victory title
	var victory_label = Label.new()
	victory_label.text = "🏆 VICTORY! 🏆"
	victory_label.position = Vector2(0, 50)
	victory_label.size = Vector2(800, 80)
	victory_label.add_theme_font_size_override("font_size", 52)
	victory_label.add_theme_color_override("font_color", Color.GOLD)
	victory_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	victory_label.add_theme_constant_override("shadow_outline_size", 5)
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_container.add_child(victory_label)

	# Premium victory message
	var victory_message = Label.new()
	victory_message.text = "You completed the 100 round challenge!"
	victory_message.position = Vector2(0, 130)
	victory_message.size = Vector2(800, 50)
	victory_message.add_theme_font_size_override("font_size", 26)
	victory_message.add_theme_color_override("font_color", Color.WHITE)
	victory_message.add_theme_color_override("font_shadow_color", Color.BLACK)
	victory_message.add_theme_constant_override("shadow_outline_size", 3)
	victory_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_container.add_child(victory_message)

	# Premium exit message
	var exit_message = Label.new()
	exit_message.text = "Game will exit in 5 seconds..."
	exit_message.position = Vector2(0, 200)
	exit_message.size = Vector2(800, 40)
	exit_message.add_theme_font_size_override("font_size", 20)
	exit_message.add_theme_color_override("font_color", Color.YELLOW)
	exit_message.add_theme_color_override("font_shadow_color", Color.BLACK)
	exit_message.add_theme_constant_override("shadow_outline_size", 2)
	exit_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_container.add_child(exit_message)

	# Premium victory animations
	victory_container.modulate = Color.TRANSPARENT
	victory_container.scale = 0.2 * Vector2.ONE

	var victory_tween = create_tween()
	victory_tween.parallel().tween_property(victory_container, "modulate", Color.WHITE, 1.0)
	victory_tween.parallel().tween_property(victory_container, "scale", Vector2.ONE, 1.0)

	# Premium fireworks effect
	create_fireworks_effect()

	# Premium pulsing victory text
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(victory_label, "scale", 1.15 * Vector2.ONE, 1.0)
	pulse_tween.tween_property(victory_label, "scale", Vector2.ONE, 1.0)

	# Exit after victory
	await get_tree().create_timer(5.0).timeout
	get_tree().quit()


func create_fireworks_effect():
	"""Create premium fireworks visual effect for victory"""
	for i in range(15):
		var firework = Label.new()
		firework.text = ["✨", "🎆", "🎇", "💫", "⭐"][i % 5]
		firework.add_theme_font_size_override("font_size", 36)
		firework.add_theme_color_override(
			"font_color",
			[Color.GOLD, Color.RED, Color.BLUE, Color.GREEN, Color.PURPLE, Color.CYAN][i % 6]
		)
		firework.position = Vector2(
			randf() * get_viewport().size.x, randf() * get_viewport().size.y
		)
		add_child(firework)

		# Premium firework animation
		var firework_tween = create_tween()
		firework_tween.parallel().tween_property(
			firework,
			"position",
			firework.position + Vector2(randf_range(-250, 250), randf_range(-250, 250)),
			2.5
		)
		firework_tween.parallel().tween_property(firework, "modulate", Color.TRANSPARENT, 2.5)
		firework_tween.parallel().tween_property(firework, "scale", 2.5 * Vector2.ONE, 2.5)
		firework_tween.tween_callback(firework.queue_free)

		await get_tree().create_timer(0.15).timeout  # Stagger fireworks


func show_aaa_game_over_popup():
	"""Premium game over screen with dramatic effects"""

	# Premium game over background with fade-in
	var game_over_bg = ColorRect.new()
	game_over_bg.color = Color(0.05, 0, 0, 0.98)
	game_over_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_over_bg)

	# Premium game over container
	var game_over_container = Panel.new()
	game_over_container.position = Vector2(
		get_viewport().size.x / 2 - 350, get_viewport().size.y / 2 - 150
	)
	game_over_container.size = Vector2(700, 300)

	var game_over_style = StyleBoxFlat.new()
	game_over_style.bg_color = Color(0.1, 0.02, 0.02, 0.98)
	game_over_style.border_width_left = 4
	game_over_style.border_width_right = 4
	game_over_style.border_width_top = 4
	game_over_style.border_width_bottom = 4
	game_over_style.border_color = Color.RED
	game_over_style.corner_radius_top_left = 25
	game_over_style.corner_radius_top_right = 25
	game_over_style.corner_radius_bottom_left = 25
	game_over_style.corner_radius_bottom_right = 25
	game_over_style.shadow_color = Color(1.0, 0.0, 0.0, 0.6)
	game_over_style.shadow_size = 15
	game_over_container.add_theme_stylebox_override("panel", game_over_style)
	add_child(game_over_container)

	# Premium Game Over title
	var game_over_label = Label.new()
	game_over_label.text = "💀 GAME OVER! 💀"
	game_over_label.position = Vector2(0, 40)
	game_over_label.size = Vector2(700, 80)
	game_over_label.add_theme_font_size_override("font_size", 46)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	game_over_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	game_over_label.add_theme_constant_override("shadow_outline_size", 5)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_container.add_child(game_over_label)

	# Premium failure message
	var failure_label = Label.new()
	failure_label.text = "You reached round %s before failing the challenge!" % current_round
	failure_label.position = Vector2(0, 120)
	failure_label.size = Vector2(700, 50)
	failure_label.add_theme_font_size_override("font_size", 22)
	failure_label.add_theme_color_override("font_color", Color.WHITE)
	failure_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	failure_label.add_theme_constant_override("shadow_outline_size", 3)
	failure_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	failure_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_container.add_child(failure_label)

	# Premium exit message
	var exit_label = Label.new()
	exit_label.text = "Returning to title in 3 seconds..."
	exit_label.position = Vector2(0, 200)
	exit_label.size = Vector2(700, 40)
	exit_label.add_theme_font_size_override("font_size", 18)
	exit_label.add_theme_color_override("font_color", Color.YELLOW)
	exit_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	exit_label.add_theme_constant_override("shadow_outline_size", 2)
	exit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_container.add_child(exit_label)

	# Premium dramatic entrance animation
	game_over_bg.modulate = Color.TRANSPARENT
	game_over_container.modulate = Color.TRANSPARENT
	game_over_container.scale = 0.2 * Vector2.ONE

	var entrance_tween = create_tween()
	entrance_tween.parallel().tween_property(game_over_bg, "modulate", Color.WHITE, 0.6)
	entrance_tween.parallel().tween_property(game_over_container, "modulate", Color.WHITE, 1.0)
	entrance_tween.parallel().tween_property(game_over_container, "scale", Vector2.ONE, 1.0)

	# Premium screen shake effect
	var shake_tween = create_tween()
	shake_tween.set_loops(8)
	shake_tween.tween_property(
		game_over_container, "position", game_over_container.position + Vector2(8, 0), 0.04
	)
	shake_tween.tween_property(
		game_over_container, "position", game_over_container.position + Vector2(-8, 0), 0.04
	)
	shake_tween.tween_property(game_over_container, "position", game_over_container.position, 0.04)

	# Premium pulsing game over text
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(game_over_label, "modulate", Color.WHITE, 0.5)
	pulse_tween.tween_property(game_over_label, "modulate", Color.RED, 0.5)


func show_aaa_popup(message: String, color: Color = Color.YELLOW):
	"""Premium popup with AAA styling and animations"""
	print("💬 " + message)

	# Create premium popup container
	var popup_container = Panel.new()
	popup_container.position = Vector2(300, 80)
	popup_container.size = Vector2(600, 70)

	# Premium popup style
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.02, 0.02, 0.08, 0.98)
	popup_style.border_width_left = 3
	popup_style.border_width_right = 3
	popup_style.border_width_top = 3
	popup_style.border_width_bottom = 3
	popup_style.border_color = color
	popup_style.corner_radius_top_left = 20
	popup_style.corner_radius_top_right = 20
	popup_style.corner_radius_bottom_left = 20
	popup_style.corner_radius_bottom_right = 20
	popup_style.shadow_color = Color(color.r, color.g, color.b, 0.5)
	popup_style.shadow_size = 12
	popup_container.add_theme_stylebox_override("panel", popup_style)
	add_child(popup_container)

	# Premium popup text
	var popup_label = Label.new()
	popup_label.text = message
	popup_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.add_theme_font_size_override("font_size", 18)
	popup_label.add_theme_color_override("font_color", color)
	popup_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	popup_label.add_theme_constant_override("shadow_outline_size", 3)
	popup_container.add_child(popup_label)

	# Premium popup animation
	popup_container.modulate = Color.TRANSPARENT
	popup_container.scale = 0.4 * Vector2.ONE

	var popup_tween = create_tween()
	popup_tween.parallel().tween_property(popup_container, "modulate", Color.WHITE, 0.4)
	popup_tween.parallel().tween_property(popup_container, "scale", Vector2.ONE, 0.4)
	popup_tween.tween_interval(2.5)
	popup_tween.parallel().tween_property(
		popup_container, "position", popup_container.position + Vector2(0, -120), 1.2
	)
	popup_tween.parallel().tween_property(popup_container, "modulate", Color.TRANSPARENT, 1.2)
	popup_tween.tween_callback(popup_container.queue_free)


# Premium helper functions for AAA effects


func create_screen_flash(color: Color, duration: float = 0.4):
	"""Create premium screen flash effect"""
	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash)

	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate", Color.TRANSPARENT, duration)
	flash_tween.tween_callback(flash.queue_free)


func create_particle_burst(burst_position: Vector2, color: Color):
	"""Create premium particle burst effect at specified position"""
	for i in range(12):
		var particle = Label.new()
		particle.text = ["●", "✦", "✧", "✨"][i % 4]
		particle.add_theme_font_size_override("font_size", 20)
		particle.add_theme_color_override("font_color", color)
		particle.position = burst_position
		add_child(particle)

		var angle = i * PI / 6  # 12 directions
		var target_pos = burst_position + Vector2(cos(angle), sin(angle)) * 120

		var particle_tween = create_tween()
		particle_tween.parallel().tween_property(particle, "burst_position", target_pos, 1.0)
		particle_tween.parallel().tween_property(particle, "modulate", Color.TRANSPARENT, 1.0)
		particle_tween.parallel().tween_property(particle, "scale", 0.1 * Vector2.ONE, 1.0)
		particle_tween.tween_callback(particle.queue_free)
