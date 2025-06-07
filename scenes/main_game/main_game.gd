class_name MainGame
extends Control

@export var autoskip_videos: bool = false

#Game State Variables
var max_rounds = 100
var current_round = 1:
	set(value):
		previous_round = current_round
		current_round = clampi(value, 1, max_rounds)
var previous_round = 1

var perk_system: PerkSystem

var dice_min = 1
var dice_max = 6
var pause_count = 1
var pause_time = 5

var is_playing = false
var video_process_id = -1

@onready var water_progress_container: Panel = %WaterProgressContainer
@onready var dice_range_label: Label = %DiceRangeLabel
@onready var perk_label: Label = %PerkLabel
@onready var active_perks: Label = %ActivePerks
@onready var pause_count_label: Label = %PauseCountLabel
@onready var action_button: ActionButton = %ActionButton
@onready var dice_result: Label = %DiceResult
@onready var coming_up_box: ComingUpBox = %ComingUpBox
@onready var countdown_bar: CountdownBar = %CountdownBar
@onready var victory_popup: VictoryPopup = %VictoryPopup
@onready var game_over_popup: GameOverPopup = %GameOverPopup

@onready var start_time: float = Time.get_unix_time_from_system()


func _ready():
	Config.clear_pause_config()

	# Initialize perk system
	perk_system = PerkSystem.new(self)
	perk_system.perk_earned.connect(_on_perk_earned)
	perk_system.perk_used.connect(_on_perk_used)
	perk_system.ui_update_needed.connect(update_all_ui_animated)

	advance_to_round(current_round)


func advance_to_round(next_round: int):
	current_round = next_round
	coming_up_box.open(current_round)
	action_button.switch_to_play()

	update_all_ui_animated()
	print("🎯 Advanced to Round: %s" % current_round)
	if current_round == max_rounds:
		Events.notified.emit(Message.new("🎮 FINAL ROUND - Click Play to watch video!", Color.CYAN))
	else:
		Events.notified.emit(
			Message.new("🎮 Round %s - Click Play to watch video!" % current_round, Color.CYAN)
		)


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
		Events.notified.emit(
			Message.new("❌ ERROR: Video file %s.mp4 not found!" % video_name, Color.RED)
		)
		action_button.switch_to_play()
		return

	if not FileAccess.file_exists(funscript_path):
		print("❌ ERROR: Funscript file not found: %s" % funscript_path)
		Events.notified.emit(
			Message.new("❌ ERROR: Funscript file %s.funscript not found!" % video_name, Color.RED)
		)
		action_button.switch_to_play()
		return

	if not FileAccess.file_exists(python_script):
		print("❌ ERROR: Python script not found: %s" % python_script)
		Events.notified.emit(
			Message.new("❌ ERROR: Script file %s not found!" % python_script, Color.RED)
		)
		action_button.switch_to_play()
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
		var notif := (
			"🎬 VLC Player launched in FULLSCREEN! Pauses: %s (%ss each)" % [pause_count, pause_time]
		)
		Events.notified.emit(Message.new(notif, Color.GREEN))
		is_playing = true
	else:
		print("❌ Failed to start Python script with any Python command")
		var notif := "❌ ERROR: Could not launch Python script! Make sure Python is installed."
		Events.notified.emit(Message.new(notif, Color.RED))
		action_button.switch_to_play()


func monitor_video_completion(max_attempts: int = 600):
	print("👀 Starting video completion monitor...")

	if autoskip_videos:
		on_video_completed()
		return

	var monitor_attempts = 0

	while video_process_id > 0 and monitor_attempts < max_attempts:
		await get_tree().create_timer(2.0).timeout
		monitor_attempts += 1
		if monitor_attempts % 15 == 0:
			print("⏳ Video still playing...")

		# Try to check if process is still alive
		if OS.is_process_running(video_process_id):
			continue
		print("🎬 Video script finished! (Auto-detected)")

		# Check for ejaculation file
		if Config.cum_exists():
			print("💀 Ejaculation file found - GAME OVER!")
			defeat()
			return
		else:
			print("✅ Normal video completion")
			on_video_completed()
			return

	print("⏰ Monitor timeout - assuming video finished")
	on_video_completed()


func on_video_completed():
	update_pause_count_from_file()
	perk_system.update_perk_timers()

	print("✅ Video completed for Round %s" % current_round)
	if current_round == max_rounds:
		victory()
		return
	perk_system.check_perk_rewards(current_round)

	is_playing = false

	action_button.switch_to_roll()
	Events.notified.emit(Message.new("🎬 Video finished! Roll the dice to continue.", Color.YELLOW))
	video_process_id = -1


func update_pause_count_from_file():
	"""Read back the updated pause count from the Python script"""

	var current_pauses = Config.load_pause_config_timestamped()

	pause_count = current_pauses + 1  # Apply the +1 stacking bonus
	print("📝 Pauses set to: %s (%s + 1 bonus)" % [pause_count, current_pauses])


# TODO: separate perks into their own scene
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
			Events.notified.emit(Message.new("No perks available!", Color.GRAY))


# TODO: separate dice animation into its own scene
func animate_dice_roll():
	dice_result.modulate = Color.WHITE

	# Animate dice numbers rapidly with premium effects
	for i in range(20):  # More frames for smoother animation
		dice_result.text = "🎲 %s" % randi_range(1, 6)

		var bounce_tween := create_tween()
		bounce_tween.tween_property(dice_result, "scale", 1.3 * Vector2.ONE, 0.04)
		bounce_tween.tween_property(dice_result, "scale", Vector2.ONE, 0.04)

		await bounce_tween.finished


# TODO: make UI elements update themselves
func update_all_ui_animated():
	"""Update all UI elements with premium smooth animations"""
	water_progress_container.current_round = current_round

	active_perks.text = perk_system.get_active_perks_display_text()
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


# TODO: move to autoload
func flash_component(component: CanvasItem) -> void:
	var flash_tween := create_tween()
	flash_tween.tween_property(component, "modulate", Color.GOLD, 0.3)
	flash_tween.tween_property(component, "modulate", Color.WHITE, 0.4)


func victory():
	Config.save_highscore(100, "victory", start_time)
	victory_popup.open()

	Events.notified.emit(
		Message.new("🏆 VICTORY! You reached round 100 without ejaculating!", Color.GOLD)
	)
	print("🏆 VICTORY! Player completed the challenge!")


func defeat():
	print("💀 EJACULATION DETECTED FROM VIDEO!")

	Config.save_highscore(current_round, "ejaculation", start_time)
	Config.clean_up_cum()

	# Kill the video process
	if video_process_id > 0:
		OS.kill(video_process_id)
		print("🛑 Killed video process")

	game_over_popup.open(current_round)

	await get_tree().create_timer(3.0).timeout
	print("👋 Returning to start menu...")
	get_tree().change_scene_to_file("uid://bcan4ssdl6xe8")


func _on_action_button_play_pressed() -> void:
	countdown_bar.stop()
	coming_up_box.close()
	launch_video_with_handy_sync()
	monitor_video_completion()


func _on_action_button_roll_pressed() -> void:
	if is_playing:
		push_warning("Button should not be active while playing")
		return

	var roll: int
	# Check for lucky 7 perk
	if perk_system.has_active_perk("lucky_7"):
		roll = 7
		perk_system.consume_active_perk("lucky_7")
		Events.notified.emit(Message.new("🍀 Lucky 7 activated! Rolled: 7", Color.GOLD))
	else:
		await animate_dice_roll()
		roll = randi_range(dice_min, dice_max)

	# TODO: separate out
	dice_result.text = "Rolled: %s" % roll
	var result_tween := create_tween()
	result_tween.tween_property(dice_result, "scale", 1.4 * Vector2.ONE, 0.4)
	result_tween.tween_property(dice_result, "scale", Vector2.ONE, 0.4)
	result_tween.tween_property(dice_result, "modulate", Color.TRANSPARENT, 2.5)

	var next_round: int = current_round + roll
	print("🎲 Rolled: ", roll, " | Next Round: ", next_round)
	if next_round >= max_rounds:
		Events.notified.emit(Message.new("🎲 Rolled %s! Moving to FINAL ROUND" % roll, Color.GOLD))
		next_round = max_rounds
	else:
		Events.notified.emit(
			Message.new("🎲 Rolled %s! Moving to round %s" % [roll, next_round], Color.GOLD)
		)

	# Wait for animations
	await get_tree().create_timer(1.8).timeout

	countdown_bar.start()

	# Move to next round
	advance_to_round(next_round)


func _on_countdown_bar_timeout() -> void:
	# TODO: auto start instead of penalize?

	# Time's up - penalize player
	print("countdown expired, applying penalty")
	countdown_bar.stop()

	# Move player back rounds as penalty
	var penalty_rounds = 5
	current_round = max(1, current_round - penalty_rounds)
	Events.notified.emit(
		Message.new("⏰ TIME'S UP! Penalty: -%s rounds!" % penalty_rounds, Color.RED)
	)
	update_all_ui_animated()
