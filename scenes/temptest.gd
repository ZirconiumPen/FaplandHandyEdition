# FapLandEnhancedUI.gd - AAA Quality UI with black theme, session timer, and water animation
extends Control

# Game State Variables
var current_round = 1
var previous_round = 1
var max_rounds = 100
# Perk System
var perk_system: PerkSystem


var dice_min = 1
var dice_max = 6
var pause_count = 1
var max_pause_stack = 10
var pause_time = 5
var current_perks = 0
var max_perks = 3

var is_playing = false
var is_paused = false
var game_active = true
var video_process_id = -1

# Session Timer Variables
var session_start_time: float = 0.0
var session_elapsed_time: float = 0.0
var timer_update_interval: float = 1.0

# UI References
var ui_elements = {}
var character_sprites = []
var current_sprite_index = 0

# Animation variables
var dice_rolling = false
var progress_tween: Tween
var water_animation_tween: Tween




func show_coming_up_next(next_round_num: int):
	
	"""Show 'Coming Up Next' animation with hardcoded sprite"""
	
	# Remove existing coming up display
	if ui_elements.has("coming_up_container"):
		ui_elements["coming_up_container"].queue_free()
		ui_elements.erase("coming_up_container")
	
	# Create coming up container
	'''var coming_up_container = Panel.new()
	coming_up_container.name = "ComingUpContainer"
	var container_size = Vector2(400, 300)
	var screen_center = Vector2(get_viewport().size) / 2
	coming_up_container.position = screen_center - container_size / 2 - Vector2(0, 30)
	coming_up_container.size = container_size'''
	
	var coming_up_container = get_node("UI/ComingUpBox")
	coming_up_container.visible = true
	
	for child in coming_up_container.get_children():
		child.queue_free()
	await get_tree().process_frame
	
	# Premium styling
	var coming_up_style = StyleBoxFlat.new()
	coming_up_style.bg_color = Color(0.02, 0.02, 0.08, 0.95)
	coming_up_style.border_width_left = 4
	coming_up_style.border_width_right = 4
	coming_up_style.border_width_top = 4
	coming_up_style.border_width_bottom = 4
	coming_up_style.border_color = Color(1.0, 0.8, 0.0, 1.0)
	coming_up_style.corner_radius_top_left = 20
	coming_up_style.corner_radius_top_right = 20
	coming_up_style.corner_radius_bottom_left = 20
	coming_up_style.corner_radius_bottom_right = 20
	coming_up_style.shadow_color = Color(1.0, 0.8, 0.0, 0.5)
	coming_up_style.shadow_size = 15
	coming_up_container.add_theme_stylebox_override("panel", coming_up_style)
	
	#add_child(coming_up_container)
	
	# "Coming Up Next" title
	var title_label = Label.new()
	title_label.text = "COMING UP NEXT"
	title_label.position = Vector2(0, 10)  # was Vector2(0, 20)
	title_label.size = Vector2(400, 40)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.GOLD)
	title_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	title_label.add_theme_constant_override("shadow_outline_size", 3)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coming_up_container.add_child(title_label)
	
	
	
	# Create AnimatedSprite2D with your existing sprite resource (hardcoded for now)
	var animated_sprite = AnimatedSprite2D.new()
	var sprite_frames = load("res://sprites/tres_files/" + str(next_round_num) + ".tres") as SpriteFrames
	animated_sprite.speed_scale=1.0
	
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.animation = "animation"
		animated_sprite.position = Vector2(200, 185)  # Center in container
		animated_sprite.scale = Vector2(1.25, 1.25)  # Same scale as your existing setup
		animated_sprite.play()
		
		coming_up_container.add_child(animated_sprite)
		print("🎬 Showing hardcoded animated sprite for round ", next_round_num)
	else:
		# Fallback if sprite can't load
		var fallback_label = Label.new()
		fallback_label.text = "🎬 Round " + str(next_round_num)
		fallback_label.position = Vector2(0, 120)
		fallback_label.size = Vector2(400, 150)
		fallback_label.add_theme_font_size_override("font_size", 48)
		fallback_label.add_theme_color_override("font_color", Color.CYAN)
		fallback_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		fallback_label.add_theme_constant_override("shadow_outline_size", 3)
		fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		coming_up_container.add_child(fallback_label)
		print("❌ Failed to load sprite frames, using fallback")
	
	# Store reference
	ui_elements["coming_up_container"] = coming_up_container
	
	# Premium entrance animation
	coming_up_container.modulate = Color.TRANSPARENT
	coming_up_container.scale = Vector2(0.3, 0.3)
	
	var entrance_tween = create_tween()
	entrance_tween.parallel().tween_property(coming_up_container, "modulate", Color.WHITE, 0.8)
	entrance_tween.parallel().tween_property(coming_up_container, "scale", Vector2(1.0, 1.0), 0.8)
	
	# Pulsing animation
	await entrance_tween.finished
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(coming_up_container, "modulate", Color(1.15, 1.15, 1.15, 1.0), 1.2)
	pulse_tween.tween_property(coming_up_container, "modulate", Color.WHITE, 1.2)
	
	print("🎯 Showing 'Coming Up Next' for Round ", next_round_num)

func hide_coming_up_next():
	"""Hide the coming up next display"""
	if ui_elements.has("coming_up_container"):
		var container = ui_elements["coming_up_container"]
		var fade_tween = create_tween()
		fade_tween.tween_property(container, "modulate", Color.TRANSPARENT, 0.5)
		fade_tween.tween_callback(func(): container.visible = false)
		ui_elements.erase("coming_up_container")
		print("👋 Hiding 'Coming Up Next' display")
		
		
		
func update_pause_count_from_file():
	"""Read back the updated pause count from the Python script"""

	
	var current_pauses = load_pause_config_timestamped()
	
	pause_count = current_pauses + 1  # Apply the +1 stacking bonus
	print("📝 Pauses set to: ", pause_count, " (", current_pauses, " + 1 bonus)")
	
				
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
	session_start_time = current_time["hour"] * 3600 + current_time["minute"] * 60 + current_time["second"]
	
	# Force solid black background
	get_viewport().get_window().set_flag(Window.FLAG_TRANSPARENT, false)
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	# Initialize perk system
	perk_system = PerkSystem.new(self)
	perk_system.perk_earned.connect(_on_perk_earned)
	perk_system.perk_used.connect(_on_perk_used)
	perk_system.ui_update_needed.connect(update_all_ui_animated)
	
	#clear_ui()
	create_aaa_ui()
	connect_ui_signals()
	start_round(current_round)
	
	
	# Start session timer updates
	start_session_timer()
	show_coming_up_next(current_round)
	#create_animated_sprite_rect()
	
	print("✅ AAA Quality UI ready with session tracking!")

func start_session_timer():
	"""Start the session timer that updates every second"""
	var timer = Timer.new()
	timer.wait_time = timer_update_interval
	timer.timeout.connect(_on_session_timer_update)
	add_child(timer)
	timer.start()
	print("⏱️ Session timer started")

func _on_session_timer_update():
	"""Update session elapsed time and UI display"""
	var current_time = Time.get_time_dict_from_system()
	var current_seconds = current_time["hour"] * 3600 + current_time["minute"] * 60 + current_time["second"]
	session_elapsed_time = current_seconds - session_start_time
	
	# Handle day rollover
	if session_elapsed_time < 0:
		session_elapsed_time += 86400  # 24 hours in seconds
	
	update_session_timer_display()

func update_session_timer_display():
	"""Update the session timer display with premium formatting"""
	if ui_elements.has("timer_label"):
		var hours = int(session_elapsed_time) / 3600
		var minutes = (int(session_elapsed_time) % 3600) / 60
		var seconds = int(session_elapsed_time) % 60
		
		var time_text = ""
		if hours > 0:
			time_text = "Session: %02d:%02d:%02d" % [hours, minutes, seconds]
		else:
			time_text = "Session: %02d:%02d" % [minutes, seconds]
		
		ui_elements["timer_label"].text = time_text

func clear_ui():
	for child in get_children():
		if child.name != "VideoStreamPlayer":
			child.queue_free()
	await get_tree().process_frame

func connect_to_scene_elements():
	"""Connect ui_elements dictionary to existing scene nodes"""
	
	# Connect to your existing scene elements - adjust paths as needed
	ui_elements["round_label"] = get_node("UI/CenterArea/RoundLabel")
	ui_elements["play_button"] = get_node("UI/CenterArea/PlayButton") 
	ui_elements["roll_button"] = get_node("UI/CenterArea/RollButton")
	
	# Left panel stats - adjust paths to match your scene structure
	
	ui_elements["dice_range_label"] = get_node("UI/LeftPanel/DiceRangeLabel")
	ui_elements["pause_count_label"] = get_node("UI/LeftPanel/PauseSettingsLabel")
	ui_elements["perk_label"] = get_node("UI/LeftPanel/PerkLabel")
	ui_elements["active_perks_label"] = get_node("UI/LeftPanel/ActivePerks")  # ADD THIS LINE
	
	# Right panel elements
	ui_elements["timer_label"] = get_node("UI/RightPanel/TimerLabel")

	
	# Create water progress bar (since this is unique to your script)
	create_water_progress_bar()
	
	# Create any missing elements that don't exist in scene
	#create_missing_elements()
	
	print("🔗 Connected to scene UI elements")

func create_missing_elements():
	"""Create elements that don't exist in the scene"""
	
	# Session timer (add to right panel)
	var right_panel = get_node("UI/RightPanel")
	var session_timer_label = Label.new()
	session_timer_label.name = "SessionTimerLabel"
	session_timer_label.text = "Session: 00:00"
	session_timer_label.position = Vector2(0, 150)  # Adjust position
	session_timer_label.size = Vector2(200, 30)
	right_panel.add_child(session_timer_label)
	ui_elements["session_timer_label"] = session_timer_label
	
	# Dice result (add to center area)
	var center_area = get_node("UI/CenterArea")
	var dice_result = Label.new()
	dice_result.name = "DiceResult"
	dice_result.text = ""
	dice_result.position = Vector2(100, 200)  # Adjust position
	dice_result.size = Vector2(200, 60)
	center_area.add_child(dice_result)
	ui_elements["dice_result"] = dice_result
	
	# Character display area
	ui_elements["character_display"] = right_panel
	
	
func create_water_progress_bar():
	"""Create the premium water progress bar"""
	var top_container = get_node("UI/TopBar")
	
	# Main progress bar container with premium glow
	var progress_container = Panel.new()
	progress_container.name = "WaterProgressContainer"
	progress_container.position = Vector2(200, 20)
	progress_container.size = Vector2(800, 60)
	
	# Premium glow effect style
	var glow_style = StyleBoxFlat.new()
	glow_style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	glow_style.border_width_left = 3
	glow_style.border_width_right = 3
	glow_style.border_width_top = 3
	glow_style.border_width_bottom = 3
	glow_style.border_color = Color(0.2, 0.4, 0.8, 0.9)
	glow_style.corner_radius_top_left = 30
	glow_style.corner_radius_top_right = 30
	glow_style.corner_radius_bottom_left = 30
	glow_style.corner_radius_bottom_right = 30
	glow_style.shadow_color = Color(0.2, 0.4, 0.8, 0.4)
	glow_style.shadow_size = 15
	progress_container.add_theme_stylebox_override("panel", glow_style)
	top_container.add_child(progress_container)
	
	# Create curved water-style progress bar
	var water_progress = Panel.new()
	water_progress.name = "WaterProgress"
	water_progress.position = Vector2(8, 8)
	water_progress.size = Vector2(1, 44)
	
	var water_style = StyleBoxFlat.new()
	water_style.bg_color = Color(0.2, 0.6, 1.0, 0.8)
	water_style.corner_radius_top_left = 22
	water_style.corner_radius_top_right = 22
	water_style.corner_radius_bottom_left = 22
	water_style.corner_radius_bottom_right = 22
	water_progress.add_theme_stylebox_override("panel", water_style)
	
	progress_container.add_child(water_progress)
	ui_elements["water_progress"] = water_progress
	ui_elements["water_style"] = water_style
	
	# Start water ripple effect
	create_water_ripple_effect(water_progress)

	# Progress text overlay
	var progress_text = Label.new()
	progress_text.name = "ProgressText"
	progress_text.position = Vector2(8, 8)
	progress_text.size = Vector2(784, 44)
	progress_text.text = "Round 1 / 100"
	progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_text.add_theme_font_size_override("font_size", 18)
	progress_text.add_theme_color_override("font_color", Color.WHITE)
	progress_text.add_theme_color_override("font_shadow_color", Color.BLACK)
	progress_text.add_theme_constant_override("shadow_outline_size", 3)
	progress_container.add_child(progress_text)
	ui_elements["progress_text"] = progress_text

func apply_premium_styling():
	"""Apply premium styling to all connected elements"""
	
	# Style buttons
	if ui_elements.has("play_button"):
		var play_button = ui_elements["play_button"]
		play_button.text = "▶ PLAY"
		play_button.add_theme_font_size_override("font_size", 20)
		
		var play_style = StyleBoxFlat.new()
		play_style.bg_color = Color(0.1, 0.7, 0.1, 0.95)
		play_style.corner_radius_top_left = 20
		play_style.corner_radius_top_right = 20
		play_style.corner_radius_bottom_left = 20
		play_style.corner_radius_bottom_right = 20
		play_style.shadow_color = Color(0.1, 0.7, 0.1, 0.6)
		play_style.shadow_size = 10
		play_button.add_theme_stylebox_override("normal", play_style)
		play_button.add_theme_color_override("font_color", Color.WHITE)
		play_button.add_theme_color_override("font_shadow_color", Color.BLACK)
		play_button.add_theme_constant_override("shadow_outline_size", 3)
	
	if ui_elements.has("roll_button"):
		var roll_button = ui_elements["roll_button"]
		roll_button.text = "🎲 ROLL DICE"
		roll_button.add_theme_font_size_override("font_size", 18)
		roll_button.disabled = true
		
		var roll_style = StyleBoxFlat.new()
		roll_style.bg_color = Color(0.6, 0.1, 0.6, 0.95)
		roll_style.corner_radius_top_left = 20
		roll_style.corner_radius_top_right = 20
		roll_style.corner_radius_bottom_left = 20
		roll_style.corner_radius_bottom_right = 20
		roll_style.shadow_color = Color(0.6, 0.1, 0.6, 0.6)
		roll_style.shadow_size = 10
		roll_button.add_theme_stylebox_override("normal", roll_style)
		roll_button.add_theme_color_override("font_color", Color.WHITE)
		roll_button.add_theme_color_override("font_shadow_color", Color.BLACK)
		roll_button.add_theme_constant_override("shadow_outline_size", 3)
	
	# Style labels
	if ui_elements.has("round_label"):
		var round_label = ui_elements["round_label"]
		round_label.add_theme_font_size_override("font_size", 48)
		round_label.add_theme_color_override("font_color", Color.WHITE)
		round_label.add_theme_color_override("font_shadow_color", Color.CYAN)
		round_label.add_theme_constant_override("shadow_outline_size", 6)
		round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		var label_style = StyleBoxFlat.new()
		label_style.bg_color = Color(0.02, 0.02, 0.05, 0.95)
		label_style.border_width_left = 2
		label_style.border_width_right = 2
		label_style.border_width_top = 2
		label_style.border_width_bottom = 2
		label_style.border_color = Color.CYAN
		label_style.corner_radius_top_left = 15
		label_style.corner_radius_top_right = 15
		label_style.corner_radius_bottom_left = 15
		label_style.corner_radius_bottom_right = 15
		label_style.shadow_color = Color(Color.CYAN.r, Color.CYAN.g, Color.CYAN.b, 0.4)
		label_style.shadow_size = 8
		round_label.add_theme_stylebox_override("normal", label_style)
	
	

	if ui_elements.has("dice_range_label") and ui_elements["dice_range_label"]:
		var label = ui_elements["dice_range_label"]
		label.text = "🎲\nDice Range\n" + str(dice_min) + "-" + str(dice_max)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.CYAN)
		label.add_theme_constant_override("shadow_outline_size", 3)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		var label_style = StyleBoxFlat.new()
		label_style.bg_color = Color(0.02, 0.02, 0.05, 0.95)
		label_style.border_width_left = 2
		label_style.border_width_right = 2
		label_style.border_width_top = 2
		label_style.border_width_bottom = 2
		label_style.border_color = Color.CYAN
		label_style.corner_radius_top_left = 15
		label_style.corner_radius_top_right = 15
		label_style.corner_radius_bottom_left = 15
		label_style.corner_radius_bottom_right = 15
		label_style.shadow_color = Color(Color.CYAN.r, Color.CYAN.g, Color.CYAN.b, 0.4)
		label_style.shadow_size = 8
		label.add_theme_stylebox_override("normal", label_style)

	if ui_elements.has("pause_count_label") and ui_elements["pause_count_label"]:
		var label = ui_elements["pause_count_label"]
		label.text = "⏸️\nPauses Left\n" + str(pause_count)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.GREEN)
		label.add_theme_constant_override("shadow_outline_size", 3)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		var label_style = StyleBoxFlat.new()
		label_style.bg_color = Color(0.02, 0.02, 0.05, 0.95)
		label_style.border_width_left = 2
		label_style.border_width_right = 2
		label_style.border_width_top = 2
		label_style.border_width_bottom = 2
		label_style.border_color = Color.GREEN
		label_style.corner_radius_top_left = 15
		label_style.corner_radius_top_right = 15
		label_style.corner_radius_bottom_left = 15
		label_style.corner_radius_bottom_right = 15
		label_style.shadow_color = Color(Color.GREEN.r, Color.GREEN.g, Color.GREEN.b, 0.4)
		label_style.shadow_size = 8
		label.add_theme_stylebox_override("normal", label_style)

	if ui_elements.has("perk_label") and ui_elements["perk_label"]:
		var label = ui_elements["perk_label"]
		label.text = "🌟\nPerks\n" + str(current_perks) + "/" + str(max_perks)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.MAGENTA)
		label.add_theme_constant_override("shadow_outline_size", 3)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		var label_style = StyleBoxFlat.new()
		label_style.bg_color = Color(0.02, 0.02, 0.05, 0.95)
		label_style.border_width_left = 2
		label_style.border_width_right = 2
		label_style.border_width_top = 2
		label_style.border_width_bottom = 2
		label_style.border_color = Color.MAGENTA
		label_style.corner_radius_top_left = 15
		label_style.corner_radius_top_right = 15
		label_style.corner_radius_bottom_left = 15
		label_style.corner_radius_bottom_right = 15
		label_style.shadow_color = Color(Color.MAGENTA.r, Color.MAGENTA.g, Color.MAGENTA.b, 0.4)
		label_style.shadow_size = 8
		label.add_theme_stylebox_override("normal", label_style)
	
	# Style other elements
	if ui_elements.has("timer_label"):
		var session_label = ui_elements["timer_label"]
		session_label.add_theme_font_size_override("font_size", 16)
		session_label.add_theme_color_override("font_color", Color.GOLD)
		session_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		session_label.add_theme_constant_override("shadow_outline_size", 2)
		
		var label_style = StyleBoxFlat.new()
		label_style.bg_color = Color(0.02, 0.02, 0.05, 0.95)
		label_style.border_width_left = 2
		label_style.border_width_right = 2
		label_style.border_width_top = 2
		label_style.border_width_bottom = 2
		label_style.border_color = Color.GOLD
		label_style.corner_radius_top_left = 15
		label_style.corner_radius_top_right = 15
		label_style.corner_radius_bottom_left = 15
		label_style.corner_radius_bottom_right = 15
		label_style.shadow_color = Color(Color.GOLD.r, Color.GOLD.g, Color.GOLD.b, 0.4)
		label_style.shadow_size = 8
		session_label.add_theme_stylebox_override("normal", label_style)
	
	if ui_elements.has("dice_result"):
		var dice_result = ui_elements["dice_result"]
		dice_result.add_theme_font_size_override("font_size", 28)
		dice_result.add_theme_color_override("font_color", Color.GOLD)
		dice_result.add_theme_color_override("font_shadow_color", Color.ORANGE)
		dice_result.add_theme_constant_override("shadow_outline_size", 4)
		dice_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dice_result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
func create_aaa_ui():
	print("🎮 Connecting to existing scene UI elements...")
	
	# Connect to existing scene elements instead of creating new ones
	connect_to_scene_elements()
	
	# Apply premium styling to existing elements
	apply_premium_styling()
	
	print("✅ Connected to scene UI elements with premium styling!")


	

func create_water_ripple_effect(water_progress: Panel):
	"""Create animated water ripple effect on the progress bar"""
	var ripple_timer = Timer.new()
	ripple_timer.wait_time = 0.1  # Update every 100ms for smooth animation
	ripple_timer.timeout.connect(func(): animate_water_ripples(water_progress))
	add_child(ripple_timer)
	ripple_timer.start()

func animate_water_ripples(water_panel: Panel):
	"""Animate water ripples using StyleBoxFlat color modulation"""
	if not ui_elements.has("water_style"):
		return
		
	var time = Time.get_ticks_msec() * 0.001  # Convert milliseconds to seconds
	var water_style = ui_elements["water_style"]
	
	# Create ripple effect using sine waves
	var ripple1 = sin(time * 3.0) * 0.1 + 1.0
	var ripple2 = sin(time * 4.5 + 1.5) * 0.08 + 1.0
	var ripple3 = sin(time * 2.0 + 3.0) * 0.05 + 1.0
	
	var combined_ripple = ripple1 * ripple2 * ripple3
	
	# Apply ripple to color brightness and alpha
	var base_color = Color(0.2, 0.6, 1.0, 0.8)
	var rippled_color = Color(
		base_color.r * combined_ripple,
		base_color.g * combined_ripple,
		base_color.b * (1.0 + sin(time * 5.0) * 0.15),  # Extra blue ripple
		base_color.a * (0.7 + sin(time * 2.5) * 0.15)   # Alpha wave
	)
	
	water_style.bg_color = rippled_color

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
	checkpoint_style.shadow_color = Color(checkpoint.color.r, checkpoint.color.g, checkpoint.color.b, 0.3)
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
	checkpoint_tween.tween_property(checkpoint_container, "modulate", Color(1.2, 1.2, 1.2, 1.0), 1.5)
	checkpoint_tween.tween_property(checkpoint_container, "modulate", Color.WHITE, 1.5)



func save_pause_config_timestamped(max_pauses_val: int, reason: String):
	"""Save pause config with timestamp and writer info"""
	var timestamp = Time.get_datetime_string_from_system(true) + "Z"
		
	# Read existing data
	var pause_data = {"entries": []}
	if FileAccess.file_exists("pause_config.json"):
		var file = FileAccess.open("pause_config.json", FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
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
	
	print("💾 Saved pause config entry: ", new_entry)
	
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
		print("🔍 DEBUG: Latest entry: ", latest_entry)
		
		# Log the full history for debugging
		print("📜 PAUSE CONFIG HISTORY:")
		var entries_sorted = pause_data["entries"].duplicate()
		entries_sorted.sort_custom(func(a, b): return a["timestamp"] < b["timestamp"])
		
		for i in range(entries_sorted.size()):
			var entry = entries_sorted[i]
			print("  ", i+1, ". ", entry["timestamp"], " | ", entry["writer"], " | pauses=", entry["max_pauses"], " | reason=", entry.get("reason", "unknown"))
		
		return int(latest_entry["max_pauses"])
	else:
		print("❌ Could not find latest entry")
		return 1
		
		





func connect_ui_signals():
	print("🔗 Connecting AAA UI signals...")
	
	if ui_elements.has("play_button"):
		ui_elements["play_button"].pressed.connect(_on_play_pressed)
		print("  ✅ Play button connected")
	
	if ui_elements.has("roll_button"):
		ui_elements["roll_button"].pressed.connect(_on_roll_pressed)
		print("  ✅ Roll button connected")
	

# Enhanced Game Logic with AAA animations
func start_round(round_num: int):
	if round_num > max_rounds:
		current_round = max_rounds
		round_num = max_rounds
	
	
	current_round = round_num
	is_playing = false
	
	# Set premium button states with animation
	if ui_elements.has("play_button"):
		ui_elements["play_button"].disabled = false
		ui_elements["play_button"].text = "▶ PLAY"
		
		# Premium button glow animation
		var button_tween = create_tween()
		button_tween.set_loops()
		button_tween.tween_property(ui_elements["play_button"], "modulate", Color(1.3, 1.3, 1.3, 1.0), 1.2)
		button_tween.tween_property(ui_elements["play_button"], "modulate", Color.WHITE, 1.2)
	
	if ui_elements.has("roll_button"):
		ui_elements["roll_button"].disabled = true
	
	update_all_ui_animated()
	print("🎯 Round ", current_round, " ready - Pauses: ", pause_count, "/1")
	show_aaa_popup("🎮 Round " + str(current_round) + " ready! You have " + str(pause_count) + " pause available.", Color.CYAN)

func _on_play_pressed():
	remove_countdown_timer()
	if not game_active:
		return
		
	previous_round = current_round
	
	print("🎬 PLAY PRESSED - Starting Round ", current_round)
	hide_coming_up_next()
	
	# Premium button state changes with animation
	if ui_elements.has("play_button"):
		ui_elements["play_button"].disabled = true
		ui_elements["play_button"].text = "🎬 PLAYING..."
		
		# Premium button press animation
		var press_tween = create_tween()
		press_tween.tween_property(ui_elements["play_button"], "scale", Vector2(0.92, 0.92), 0.1)
		press_tween.tween_property(ui_elements["play_button"], "scale", Vector2(1.0, 1.0), 0.15)
		press_tween.tween_property(ui_elements["play_button"], "modulate", Color(0.6, 0.6, 0.6, 1.0), 0.3)
	
	if ui_elements.has("roll_button"):
		ui_elements["roll_button"].disabled = true
	
	is_playing = true
	
	# Launch Python VLC script with handy sync
	launch_video_with_handy_sync()
	
	# Start monitoring for video completion
	monitor_video_completion()


func launch_video_with_handy_sync():
	
	
	
	save_pause_config_timestamped(pause_count, "round_start")
	
	var video_name = str(current_round)
	var python_script = "scripts/sync_handy.py"
	
	print("🚀 Launching Python script: ", python_script, " with video: ", video_name)
	
	# Check if files exist before launching
	var video_path = "media/" + video_name + ".mp4"
	var funscript_path = "media/" + video_name + ".funscript"
	
	if not FileAccess.file_exists(video_path):
		print("❌ ERROR: Video file not found: ", video_path)
		show_aaa_popup("❌ ERROR: Video file " + video_name + ".mp4 not found!", Color.RED)
		reset_play_button()
		return
	
	if not FileAccess.file_exists(funscript_path):
		print("❌ ERROR: Funscript file not found: ", funscript_path)
		show_aaa_popup("❌ ERROR: Funscript file " + video_name + ".funscript not found!", Color.RED)
		reset_play_button()
		return
	
	if not FileAccess.file_exists(python_script):
		print("❌ ERROR: Python script not found: ", python_script)
		show_aaa_popup("❌ ERROR: sync_handy.py not found in scripts folder!", Color.RED)
		reset_play_button()
		return
	
	print("✅ All files found, launching Python script...")
	
	# Try different Python commands
	var python_commands = ["python", "python3", "py"]
	var process_id = -1
	
	for python_cmd in python_commands:
		print("🐍 Trying Python command: ", python_cmd)
		var args = [python_script, video_name]
		process_id = OS.create_process(python_cmd, args)
		
		if process_id > 0:
			print("✅ Success with ", python_cmd)
			break
		else:
			print("❌ Failed with ", python_cmd)
	
	if process_id > 0:
		video_process_id = process_id
		print("✅ Python VLC+Handy script started with PID: ", video_process_id)
		show_aaa_popup("🎬 VLC Player launched in FULLSCREEN! Pauses: " + str(pause_count) + " (" + str(pause_time) + "s each)", Color.GREEN)
	else:
		print("❌ Failed to start Python script with any Python command")
		show_aaa_popup("❌ ERROR: Could not launch Python script! Make sure Python is installed.", Color.RED)
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
	
	# Remove video finished button
	if ui_elements.has("video_finished_button"):
		ui_elements["video_finished_button"].queue_free()
		ui_elements.erase("video_finished_button")
	
	# Disable all game controls
	game_active = false
	if ui_elements.has("play_button"):
		ui_elements["play_button"].disabled = true
	if ui_elements.has("roll_button"):
		ui_elements["roll_button"].disabled = true
	
	await get_tree().create_timer(3.0).timeout
	print("👋 Returning to start menu...")
	get_tree().change_scene_to_file("res://scenes/startup.tscn")

func on_video_completed():
	
	
	update_pause_count_from_file()
	perk_system.update_perk_timers()
	
	
	print("✅ Video completed for Round ", current_round)
	if current_round == max_rounds:
		victory()
		return
	perk_system.check_perk_rewards(current_round)

	
	is_playing = false
	
	# Premium button state changes with animation
	if ui_elements.has("roll_button"):
		ui_elements["roll_button"].disabled = false
		
		# Premium roll button activation animation
		var activate_tween = create_tween()
		activate_tween.tween_property(ui_elements["roll_button"], "modulate", Color.WHITE, 0.4)
		activate_tween.tween_property(ui_elements["roll_button"], "scale", Vector2(1.08, 1.08), 0.3)
		activate_tween.tween_property(ui_elements["roll_button"], "scale", Vector2(1.0, 1.0), 0.3)
		
		# Add premium glow effect
		var glow_tween = create_tween()
		glow_tween.set_loops()
		glow_tween.tween_property(ui_elements["roll_button"], "modulate", Color(1.3, 1.3, 1.3, 1.0), 1.2)
		glow_tween.tween_property(ui_elements["roll_button"], "modulate", Color.WHITE, 1.2)
	
	if ui_elements.has("play_button"):
		ui_elements["play_button"].text = "▶ PLAY"
		ui_elements["play_button"].modulate = Color(0.6, 0.6, 0.6, 1.0)
	
	show_aaa_popup("🎬 Video finished! Roll the dice to continue.", Color.YELLOW)
	video_process_id = -1
	

func reset_play_button():
	if ui_elements.has("play_button"):
		ui_elements["play_button"].disabled = false
		ui_elements["play_button"].text = "▶ PLAY"
		ui_elements["play_button"].modulate = Color.WHITE
	is_playing = false
	video_process_id = -1

func start_play_countdown_timer():
	"""Start 30-second countdown timer for clicking play button"""
	var countdown_time = 30
	
	# Create countdown display
	var countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.text = "Click PLAY in: " + str(countdown_time) + "s"
	countdown_label.position = Vector2(450, 590)
	countdown_label.size = Vector2(400, 40)
	countdown_label.add_theme_font_size_override("font_size", 20)
	countdown_label.add_theme_color_override("font_color", Color.ORANGE)
	countdown_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	countdown_label.add_theme_constant_override("shadow_outline_size", 3)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(countdown_label)
	ui_elements["countdown_label"] = countdown_label
	
	# Create and store the timer
	var countdown_timer = Timer.new()
	countdown_timer.name = "CountdownTimer" 
	countdown_timer.wait_time = 1.0
	countdown_timer.timeout.connect(func(): update_countdown_timer(countdown_timer, countdown_label, countdown_time))
	add_child(countdown_timer)
	countdown_timer.start()
	
	# Store timer reference so we can properly clean it up
	ui_elements["countdown_timer"] = countdown_timer
	
	print("started countdown with timer: ", countdown_timer.get_instance_id())

func update_countdown_timer(timer: Timer, label: Label, time_left: int):
	"""Update countdown timer display"""
	time_left -= 1
	
	# Check if timer was already removed (play button pressed)
	if not is_instance_valid(timer) or not timer.is_inside_tree():
		print("countdown timer was already cleaned up, stopping")
		return
	
	if time_left <= 0:
		# Time's up - penalize player
		print("countdown expired, applying penalty")
		cleanup_countdown_timer()
		
		# Move player back rounds as penalty
		var penalty_rounds = 5
		current_round = max(1, current_round - penalty_rounds)
		show_aaa_popup("⏰ TIME'S UP! Penalty: -" + str(penalty_rounds) + " rounds!", Color.RED)
		update_all_ui_animated()
		return
	
	# Update display
	if is_instance_valid(label) and label.is_inside_tree():
		label.text = "Click PLAY in: " + str(time_left) + "s"
		
		# Change color as time runs out
		if time_left <= 10:
			label.add_theme_color_override("font_color", Color.RED)
		elif time_left <= 20:
			label.add_theme_color_override("font_color", Color.YELLOW)
	
	# Continue countdown with updated time
	timer.timeout.connect(func(): update_countdown_timer(timer, label, time_left), CONNECT_ONE_SHOT)

func remove_countdown_timer():
	"""Remove countdown timer when play button is clicked"""
	print("removing countdown timer")
	cleanup_countdown_timer()

func cleanup_countdown_timer():
	"""Clean up countdown timer and label properly"""
	# Clean up label
	if ui_elements.has("countdown_label"):
		var label = ui_elements["countdown_label"]
		if is_instance_valid(label):
			label.queue_free()
		ui_elements.erase("countdown_label")
	
	# Clean up timer
	if ui_elements.has("countdown_timer"):
		var timer = ui_elements["countdown_timer"]
		if is_instance_valid(timer):
			timer.stop()
			# Remove the timer from the scene tree to break any remaining connections
			if timer.get_parent():
				timer.get_parent().remove_child(timer)
			timer.queue_free()
		ui_elements.erase("countdown_timer")
	
	print("countdown timer cleaned up")


func _on_perk_earned(perk_id: String):
	"""Handle perk earned signal"""
	make_perk_label_clickable()

func _on_perk_used(perk_id: String):
	"""Handle perk used signal"""
	print("🎯 Perk used in main game: ", perk_id)

func make_perk_label_clickable():
	"""Make the perk label clickable"""
	if ui_elements.has("perk_label"):
		var perk_label = ui_elements["perk_label"]
		
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


	
	
func _on_roll_pressed():
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
		if ui_elements.has("roll_button"):
			ui_elements["roll_button"].disabled = true
			ui_elements["roll_button"].text = "🎲 ROLLING..."
		
		# Premium dice roll animation
		await animate_dice_roll()
		
		# Roll dice and calculate next round
		roll = randi_range(dice_min, dice_max)
		next_round = current_round + roll
	
		print("🎲 Rolled: ", roll, " | Next Round: ", next_round)
	
	# Show dice result with premium animation
	if ui_elements.has("dice_result"):
		ui_elements["dice_result"].text = "Rolled: " + str(roll)
		var result_tween = create_tween()
		result_tween.tween_property(ui_elements["dice_result"], "scale", Vector2(1.4, 1.4), 0.4)
		result_tween.tween_property(ui_elements["dice_result"], "scale", Vector2(1.0, 1.0), 0.4)
		result_tween.tween_property(ui_elements["dice_result"], "modulate", Color.TRANSPARENT, 2.5)
	
	if next_round >= max_rounds:
		show_aaa_popup("🎲 Rolled " + str(roll) + "! Moving to FINAL ROUND", Color.GOLD)
	else:
		show_aaa_popup("🎲 Rolled " + str(roll) + "! Moving to round " + str(next_round), Color.GOLD)
	next_round = min(next_round,max_rounds)
	
	# Wait for animations
	await get_tree().create_timer(1.8).timeout
	
	# Show "Coming Up Next" display
	show_coming_up_next(next_round)

	
	start_play_countdown_timer()
	
	# Move to next round
	advance_to_round(next_round)
	dice_rolling = false


func animate_dice_roll():
	"""Create premium visual dice rolling animation"""
	if not ui_elements.has("dice_result"):
		return
	
	var dice_label = ui_elements["dice_result"]
	dice_label.modulate = Color.WHITE
	
	# Animate dice numbers rapidly with premium effects
	for i in range(20):  # More frames for smoother animation
		var random_num = randi_range(1, 6)
		dice_label.text = "🎲 " + str(random_num)
		
		# Premium bounce effect
		var bounce_tween = create_tween()
		bounce_tween.tween_property(dice_label, "scale", Vector2(1.3, 1.3), 0.04)
		bounce_tween.tween_property(dice_label, "scale", Vector2(1.0, 1.0), 0.04)
		
		await get_tree().create_timer(0.08)


func save_highscore(round_reached: int, reason: String):
	"""Save the highscore with timestamp"""
	var timestamp = Time.get_datetime_string_from_system(true)
	var session_time = session_elapsed_time
	
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
	if file:
		file.store_string(JSON.stringify({"scores": highscores}))
		file.close()
		print("💾 Saved highscore: Round ", round_reached, " (", reason, ")")
	else:
		print("❌ Could not save highscore file")

func load_highscores() -> Array:
	"""Load highscores from file"""
	if not FileAccess.file_exists("highscores.json"):
		return []
	
	var file = FileAccess.open("highscores.json", FileAccess.READ)
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

func get_best_round() -> int:
	"""Get the highest round reached"""
	var highscores = load_highscores()
	if highscores.size() > 0:
		return highscores[0]["round"]
	else:
		return 0





func advance_to_round(next_round: int):
	
	current_round = next_round
	# Premium button state changes
	if ui_elements.has("play_button"):
		ui_elements["play_button"].disabled = false
		ui_elements["play_button"].text = "▶ PLAY"
		ui_elements["play_button"].modulate = Color.WHITE
		
		# Re-enable premium play button glow
		var glow_tween = create_tween()
		glow_tween.set_loops()
		glow_tween.tween_property(ui_elements["play_button"], "modulate", Color(1.3, 1.3, 1.3, 1.0), 1.2)
		glow_tween.tween_property(ui_elements["play_button"], "modulate", Color.WHITE, 1.2)
	
	
	update_all_ui_animated()
	print("🎯 Advanced to Round: ", current_round)
	if current_round == max_rounds:
		show_aaa_popup("🎮 FINAL ROUND - Click Play to watch video!", Color.CYAN)
	else:
		show_aaa_popup("🎮 Round " + str(current_round) + " - Click Play to watch video!", Color.CYAN)

func get_active_perks_display_text() -> String:
	"""Get display text for active perks"""
	return perk_system.get_active_perks_display_text()

func update_all_ui_animated():
	"""Update all UI elements with premium smooth animations"""
	
	# Animate water progress bar with premium fluid effects
	if ui_elements.has("water_progress") and ui_elements.has("water_style"):
		var water_progress = ui_elements["water_progress"]
		var water_style = ui_elements["water_style"]
		var progress_ratio = float(current_round) / float(max_rounds)
		var target_width = max(1, progress_ratio * 784)  # 784 is the full progress bar width, minimum 1px
		
		# Premium smooth water progress animation
		if water_animation_tween:
			water_animation_tween.kill()
		water_animation_tween = create_tween()
		water_animation_tween.tween_property(water_progress, "size:x", target_width, 1.5)
		
		# Premium color transition based on progress (water style)
		var base_water_color = Color(0.2, 0.6, 1.0, 0.8).lerp(Color(1.0, 0.3, 0.2, 0.8), progress_ratio)
		water_style.bg_color = base_water_color
	
	# Update progress text
	if ui_elements.has("progress_text"):
		ui_elements["progress_text"].text = "Round " + str(current_round) + " / " + str(max_rounds)
	
	# Animate round number with premium effects
	if ui_elements.has("round_label"):
		var round_label = ui_elements["round_label"]
		
		# Premium scale animation for round change
		var scale_tween = create_tween()
		scale_tween.tween_property(round_label, "scale", Vector2(1.3, 1.3), 0.4)
		scale_tween.tween_property(round_label, "scale", Vector2(1.0, 1.0), 0.4)
		
		# Update text
		if current_round == max_rounds:
			round_label.text = "FINAL ROUND"
		else:
			round_label.text = "Round " + str(current_round)
	
	# Update other UI elements with premium animations
	var ui_updates = [
	{"element": "active_perks_label", "value": get_active_perks_display_text()},
	{"element": "dice_range_label", "value": "🎲\nDice Range\n" + str(dice_min) + "-" + str(dice_max)},
	{"element": "pause_count_label", "value": "⏸️\nPauses Left\n" + str(pause_count)},
	{"element": "pause_time_label", "value": "⏱️\nPause Duration\n" + str(pause_time) + "s"},
	{"element": "perk_label", "value": perk_system.get_perk_display_text()}
	]
	
	for update in ui_updates:
		if ui_elements.has(update.element):
			var label = ui_elements[update.element]
			label.text = update.value
			
			# Premium flash animation for value change
			var flash_tween = create_tween()
			flash_tween.tween_property(label, "modulate", Color.GOLD, 0.3)
			flash_tween.tween_property(label, "modulate", Color.WHITE, 0.4)
	
	print("📊 UI Updated with premium animations - Round:", current_round, "Pauses:", pause_count)

func update_timer_display():
	if ui_elements.has("timer_label"):
		if is_paused:
			# Timer shows pause countdown (handled in trigger_pause)
			pass
		else:
			ui_elements["timer_label"].text = "Game Time: 0:00"
	
	# Update session timer is handled automatically by _on_session_timer_update()


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
	victory_container.position = Vector2(get_viewport().size.x / 2 - 400, get_viewport().size.y / 2 - 150)
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
	victory_container.scale = Vector2(0.2, 0.2)
	
	var victory_tween = create_tween()
	victory_tween.parallel().tween_property(victory_container, "modulate", Color.WHITE, 1.0)
	victory_tween.parallel().tween_property(victory_container, "scale", Vector2(1.0, 1.0), 1.0)
	
	# Premium fireworks effect
	create_fireworks_effect()
	
	# Premium pulsing victory text
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(victory_label, "scale", Vector2(1.15, 1.15), 1.0)
	pulse_tween.tween_property(victory_label, "scale", Vector2(1.0, 1.0), 1.0)
	
	# Exit after victory
	await get_tree().create_timer(5.0).timeout
	get_tree().quit()

func create_fireworks_effect():
	"""Create premium fireworks visual effect for victory"""
	for i in range(15):
		var firework = Label.new()
		firework.text = ["✨", "🎆", "🎇", "💫", "⭐"][i % 5]
		firework.add_theme_font_size_override("font_size", 36)
		firework.add_theme_color_override("font_color", [Color.GOLD, Color.RED, Color.BLUE, Color.GREEN, Color.PURPLE, Color.CYAN][i % 6])
		firework.position = Vector2(randf() * get_viewport().size.x, randf() * get_viewport().size.y)
		add_child(firework)
		
		# Premium firework animation
		var firework_tween = create_tween()
		firework_tween.parallel().tween_property(firework, "position", firework.position + Vector2(randf_range(-250, 250), randf_range(-250, 250)), 2.5)
		firework_tween.parallel().tween_property(firework, "modulate", Color.TRANSPARENT, 2.5)
		firework_tween.parallel().tween_property(firework, "scale", Vector2(2.5, 2.5), 2.5)
		firework_tween.tween_callback(firework.queue_free)
		
		await get_tree().create_timer(0.15)  # Stagger fireworks

func show_aaa_game_over_popup():
	"""Premium game over screen with dramatic effects"""
	
	# Premium game over background with fade-in
	var game_over_bg = ColorRect.new()
	game_over_bg.color = Color(0.05, 0, 0, 0.98)
	game_over_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_over_bg)
	
	# Premium game over container
	var game_over_container = Panel.new()
	game_over_container.position = Vector2(get_viewport().size.x / 2 - 350, get_viewport().size.y / 2 - 150)
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
	failure_label.text = "You reached round " + str(current_round) + " before failing the challenge!"
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
	game_over_container.scale = Vector2(0.2, 0.2)
	
	var entrance_tween = create_tween()
	entrance_tween.parallel().tween_property(game_over_bg, "modulate", Color.WHITE, 0.6)
	entrance_tween.parallel().tween_property(game_over_container, "modulate", Color.WHITE, 1.0)
	entrance_tween.parallel().tween_property(game_over_container, "scale", Vector2(1.0, 1.0), 1.0)
	
	# Premium screen shake effect
	var shake_tween = create_tween()
	shake_tween.set_loops(8)
	shake_tween.tween_property(game_over_container, "position", game_over_container.position + Vector2(8, 0), 0.04)
	shake_tween.tween_property(game_over_container, "position", game_over_container.position + Vector2(-8, 0), 0.04)
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
	popup_container.scale = Vector2(0.4, 0.4)
	
	var popup_tween = create_tween()
	popup_tween.parallel().tween_property(popup_container, "modulate", Color.WHITE, 0.4)
	popup_tween.parallel().tween_property(popup_container, "scale", Vector2(1.0, 1.0), 0.4)
	popup_tween.tween_interval(2.5)
	popup_tween.parallel().tween_property(popup_container, "position", popup_container.position + Vector2(0, -120), 1.2)
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

func create_particle_burst(position: Vector2, color: Color):
	"""Create premium particle burst effect at specified position"""
	for i in range(12):
		var particle = Label.new()
		particle.text = ["●", "✦", "✧", "✨"][i % 4]
		particle.add_theme_font_size_override("font_size", 20)
		particle.add_theme_color_override("font_color", color)
		particle.position = position
		add_child(particle)
		
		var angle = i * PI / 6  # 12 directions
		var target_pos = position + Vector2(cos(angle), sin(angle)) * 120
		
		var particle_tween = create_tween()
		particle_tween.parallel().tween_property(particle, "position", target_pos, 1.0)
		particle_tween.parallel().tween_property(particle, "modulate", Color.TRANSPARENT, 1.0)
		particle_tween.parallel().tween_property(particle, "scale", Vector2(0.1, 0.1), 1.0)
		particle_tween.tween_callback(particle.queue_free)
