class_name MainGame
extends Control

@export var autoskip_videos: bool = false
@export var countdown_time: float = 30.0

#Game State Variables
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

@onready var water_progress_container: Panel = %WaterProgressContainer
@onready var dice_range_label: Label = %DiceRangeLabel
@onready var perk_label: Label = %PerkLabel
@onready var active_perks: Label = %ActivePerks
@onready var pause_count_label: Label = %PauseCountLabel
@onready var action_button: Control = %ActionButton
@onready var play_button: Button = %PlayButton
@onready var roll_button: Button = %RollButton
@onready var dice_result: Label = %DiceResult
@onready var coming_up_box: Panel = %ComingUpBox
@onready var countdown_label: Label = %CountdownLabel
@onready var countdown_timer: Timer = $CountdownTimer
@onready var victory_popup: VictoryPopup = %VictoryPopup
@onready var game_over_popup: GameOverPopup = %GameOverPopup

@onready var start_time: float = Time.get_unix_time_from_system()


func _ready():
	clear_pause_config()

	# Initialize perk system
	perk_system = PerkSystem.new(self)
	perk_system.perk_earned.connect(_on_perk_earned)
	perk_system.perk_used.connect(_on_perk_used)
	perk_system.ui_update_needed.connect(update_all_ui_animated)

	coming_up_box.open(current_round)
	start_round(current_round)


func clear_pause_config() -> void:
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
	button_tween.tween_property(action_button, "modulate", Color(1.3, 1.3, 1.3), 1.2)
	button_tween.tween_property(action_button, "modulate", Color.WHITE, 1.2)

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
	press_tween.tween_property(action_button, "scale", 0.92 * Vector2.ONE, 0.1)
	press_tween.tween_property(action_button, "scale", Vector2.ONE, 0.15)
	press_tween.tween_property(action_button, "modulate", Color(0.6, 0.6, 0.6), 0.3)

	roll_button.disabled = true

	is_playing = true

	# Launch Python VLC script with handy sync
	launch_video_with_handy_sync()

	# Start monitoring for video completion
	monitor_video_completion()


func launch_video_with_handy_sync():
	if autoskip_videos:
		print("autoskip enabled, skipping video")
		return
	Config.save_pause_config_timestamped(pause_count, "round_start", pause_time)

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
	var python_commands = ["py", "python", "python3"]
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

	if autoskip_videos:
		on_video_completed()
		return

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

	Config.save_highscore(current_round, "ejaculation", start_time)

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

	game_over_popup.open(current_round)

	# Disable all game controls
	game_active = false
	play_button.disabled = true
	roll_button.disabled = true

	await get_tree().create_timer(3.0).timeout
	print("👋 Returning to start menu...")
	get_tree().change_scene_to_file("uid://bcan4ssdl6xe8")


func on_video_completed():
	update_pause_count_from_file()
	perk_system.update_perk_timers()

	print("✅ Video completed for Round %s" % current_round)
	if current_round == max_rounds:
		victory()
		return
	perk_system.check_perk_rewards(current_round)

	is_playing = false

	play_button.hide()
	roll_button.show()
	roll_button.disabled = false

	var activate_tween := create_tween()
	activate_tween.tween_property(action_button, "modulate", Color.WHITE, 0.4)
	activate_tween.tween_property(action_button, "scale", 1.08 * Vector2.ONE, 0.3)
	activate_tween.tween_property(action_button, "scale", Vector2.ONE, 0.3)

	var glow_tween := create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(action_button, "modulate", Color(1.3, 1.3, 1.3), 1.2)
	glow_tween.tween_property(action_button, "modulate", Color.WHITE, 1.2)

	play_button.text = "▶ PLAY"
	play_button.modulate = Color(0.6, 0.6, 0.6, 1.0)

	show_aaa_popup("🎬 Video finished! Roll the dice to continue.", Color.YELLOW)
	video_process_id = -1


func update_pause_count_from_file():
	"""Read back the updated pause count from the Python script"""

	var current_pauses = Config.load_pause_config_timestamped()

	pause_count = current_pauses + 1  # Apply the +1 stacking bonus
	print("📝 Pauses set to: %s (%s + 1 bonus)" % [pause_count, current_pauses])


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
	roll_button.disabled = true
	if not game_active or is_playing:
		return

	print("🎲 ROLL PRESSED")
	var roll
	var next_round
	# Check for lucky 7 perk
	if perk_system.has_active_perk("lucky_7"):
		roll = 7
		perk_system.consume_active_perk("lucky_7")
		show_aaa_popup("🍀 Lucky 7 activated! Rolled: 7", Color.GOLD)
		next_round = current_round + roll
	else:
		roll_button.text = "🎲 ROLLING..."

		await animate_dice_roll()

		# Roll dice and calculate next round
		roll = randi_range(dice_min, dice_max)
		next_round = current_round + roll

		roll_button.text = "🎲 ROLL DICE"
		print("🎲 Rolled: ", roll, " | Next Round: ", next_round)

	roll_button.hide()
	play_button.show()

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


func animate_dice_roll():
	dice_result.modulate = Color.WHITE

	# Animate dice numbers rapidly with premium effects
	for i in range(20):  # More frames for smoother animation
		dice_result.text = "🎲 %s" % randi_range(1, 6)

		var bounce_tween := create_tween()
		bounce_tween.tween_property(dice_result, "scale", 1.3 * Vector2.ONE, 0.04)
		bounce_tween.tween_property(dice_result, "scale", Vector2.ONE, 0.04)

		await bounce_tween.finished


func advance_to_round(next_round: int):
	current_round = next_round
	# Premium button state changes
	play_button.disabled = false
	play_button.text = "▶ PLAY"
	play_button.modulate = Color.WHITE

	# Re-enable premium play button glow
	var glow_tween := create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(action_button, "modulate", Color(1.3, 1.3, 1.3), 1.2)
	glow_tween.tween_property(action_button, "modulate", Color.WHITE, 1.2)

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
	Config.save_highscore(100, "victory", start_time)
	victory_popup.open()

	show_aaa_popup("🏆 VICTORY! You reached round 100 without ejaculating!", Color.GOLD)
	print("🏆 VICTORY! Player completed the challenge!")


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
