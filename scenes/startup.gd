# StartMenu.gd - Premium AAA Quality Start Menu
extends Control

# UI References
var ui_elements = {}
var background_particles = []
var title_animation_tween: Tween
var particle_timer: Timer

# Animation variables
var floating_emojis = ["🎮", "🎲", "🎬", "⭐", "💎", "🔥", "✨", "🌟"]
var current_emoji_index = 0

@onready var main_container: Control = $MainContainer


func _ready():
	print("🎮 Creating Premium FapLand Start Menu...")
	get_node("HowToPlayBox").visible = false
	get_node("PopupBox").visible = false

	# Force solid black background
	RenderingServer.set_default_clear_color(Color.BLACK)

	create_start_menu()
	start_background_animations()
	play_entrance_animation()

	print("✅ Premium Start Menu ready!")


func create_start_menu():
	"""Create the premium start menu interface"""

	# Create animated background particles
	create_background_particles(main_container)

	# Menu buttons section
	create_menu_section(main_container)
	create_highscore_panel(main_container)

	# Footer info
	create_footer_section(main_container)


func create_background_particles(parent: Control):
	"""Create floating background particles for atmosphere"""

	for i in range(20):
		var particle = Label.new()
		particle.text = floating_emojis[i % floating_emojis.size()]
		particle.add_theme_font_size_override("font_size", randi_range(24, 48))
		particle.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, randf_range(0.1, 0.3)))
		particle.position = Vector2(
			randf() * get_viewport().size.x, randf() * get_viewport().size.y
		)
		parent.add_child(particle)
		background_particles.append(particle)

		# Start individual particle animation
		animate_particle(particle)


func animate_particle(particle: Label):
	"""Animate individual background particle"""
	var move_tween = create_tween()
	move_tween.set_loops()

	var start_pos = particle.position
	var target_pos = Vector2(
		start_pos.x + randf_range(-100, 100), start_pos.y + randf_range(-50, 50)
	)

	var duration = randf_range(8.0, 15.0)

	move_tween.tween_property(particle, "position", target_pos, duration)
	move_tween.tween_property(particle, "position", start_pos, duration)

	# Fade animation
	var fade_tween = create_tween()
	fade_tween.set_loops()
	fade_tween.tween_property(particle, "modulate:a", randf_range(0.05, 0.4), randf_range(3.0, 6.0))
	fade_tween.tween_property(particle, "modulate:a", randf_range(0.1, 0.2), randf_range(3.0, 6.0))


func create_menu_section(parent: Control):
	"""Create the menu buttons section"""

	var menu_container = Control.new()
	menu_container.name = "MenuContainer"
	menu_container.position = Vector2(get_viewport().size.x / 2 - 200, 350)
	menu_container.size = Vector2(400, 300)
	parent.add_child(menu_container)
	ui_elements["menu_container"] = menu_container

	# START GAME button (main button)
	var start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "🚀 START GAME"
	start_button.position = Vector2(50, 50)
	start_button.size = Vector2(300, 80)
	start_button.add_theme_font_size_override("font_size", 32)

	# Premium start button styling
	var start_style = StyleBoxFlat.new()
	start_style.bg_color = Color(0.1, 0.8, 0.1, 0.95)
	start_style.corner_radius_top_left = 25
	start_style.corner_radius_top_right = 25
	start_style.corner_radius_bottom_left = 25
	start_style.corner_radius_bottom_right = 25
	start_style.shadow_color = Color(0.1, 0.8, 0.1, 0.7)
	start_style.shadow_size = 15
	start_button.add_theme_stylebox_override("normal", start_style)
	start_button.add_theme_color_override("font_color", Color.WHITE)
	start_button.add_theme_color_override("font_shadow_color", Color.BLACK)
	start_button.add_theme_constant_override("shadow_outline_size", 4)

	# Hover effect styling
	var start_hover_style = StyleBoxFlat.new()
	start_hover_style.bg_color = Color(0.15, 0.9, 0.15, 0.95)
	start_hover_style.corner_radius_top_left = 25
	start_hover_style.corner_radius_top_right = 25
	start_hover_style.corner_radius_bottom_left = 25
	start_hover_style.corner_radius_bottom_right = 25
	start_hover_style.shadow_color = Color(0.15, 0.9, 0.15, 0.9)
	start_hover_style.shadow_size = 20
	start_button.add_theme_stylebox_override("hover", start_hover_style)

	menu_container.add_child(start_button)
	ui_elements["start_button"] = start_button

	# Connect start button signal
	start_button.pressed.connect(_on_start_game_pressed)

	# HOW TO PLAY button
	var how_to_play_button = Button.new()
	how_to_play_button.name = "HowToPlayButton"
	how_to_play_button.text = "❓ HOW TO PLAY"
	how_to_play_button.position = Vector2(50, 150)
	how_to_play_button.size = Vector2(300, 60)
	how_to_play_button.add_theme_font_size_override("font_size", 24)

	# Premium how-to-play button styling
	var help_style = StyleBoxFlat.new()
	help_style.bg_color = Color(0.2, 0.4, 0.8, 0.95)
	help_style.corner_radius_top_left = 20
	help_style.corner_radius_top_right = 20
	help_style.corner_radius_bottom_left = 20
	help_style.corner_radius_bottom_right = 20
	help_style.shadow_color = Color(0.2, 0.4, 0.8, 0.6)
	help_style.shadow_size = 12
	how_to_play_button.add_theme_stylebox_override("normal", help_style)
	how_to_play_button.add_theme_color_override("font_color", Color.WHITE)
	how_to_play_button.add_theme_color_override("font_shadow_color", Color.BLACK)
	how_to_play_button.add_theme_constant_override("shadow_outline_size", 3)

	menu_container.add_child(how_to_play_button)
	ui_elements["how_to_play_button"] = how_to_play_button

	# Connect how to play button signal
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)

	# EXIT button
	var exit_button = Button.new()
	exit_button.name = "ExitButton"
	exit_button.text = "🚪 EXIT"
	exit_button.position = Vector2(50, 230)
	exit_button.size = Vector2(300, 50)
	exit_button.add_theme_font_size_override("font_size", 20)

	# Premium exit button styling
	var exit_style = StyleBoxFlat.new()
	exit_style.bg_color = Color(0.7, 0.2, 0.2, 0.95)
	exit_style.corner_radius_top_left = 15
	exit_style.corner_radius_top_right = 15
	exit_style.corner_radius_bottom_left = 15
	exit_style.corner_radius_bottom_right = 15
	exit_style.shadow_color = Color(0.7, 0.2, 0.2, 0.5)
	exit_style.shadow_size = 8
	exit_button.add_theme_stylebox_override("normal", exit_style)
	exit_button.add_theme_color_override("font_color", Color.WHITE)
	exit_button.add_theme_color_override("font_shadow_color", Color.BLACK)
	exit_button.add_theme_constant_override("shadow_outline_size", 2)

	var exit_hover_style = StyleBoxFlat.new()
	exit_hover_style.bg_color = Color(0.8, 0.3, 0.3, 0.95)
	exit_hover_style.corner_radius_top_left = 15
	exit_hover_style.corner_radius_top_right = 15
	exit_hover_style.corner_radius_bottom_left = 15
	exit_hover_style.corner_radius_bottom_right = 15
	exit_hover_style.shadow_color = Color(0.8, 0.3, 0.3, 0.7)
	exit_hover_style.shadow_size = 12
	exit_button.add_theme_stylebox_override("hover", exit_hover_style)

	menu_container.add_child(exit_button)
	ui_elements["exit_button"] = exit_button

	# Connect exit button signal
	exit_button.pressed.connect(_on_exit_pressed)


func create_footer_section(parent: Control):
	"""Create footer with game info and credits"""

	var footer_container = Control.new()
	footer_container.name = "FooterContainer"
	footer_container.position = Vector2(0, get_viewport().size.y - 100)
	footer_container.size = Vector2(get_viewport().size.x, 50)
	parent.add_child(footer_container)

	# Game info
	var info_label = Label.new()
	info_label.text = "🎯 Reach Round 100 without ejaculating • 🎲 Roll dice to advance • ⏸️ Use pauses wisely"
	info_label.position = Vector2(0, -520)
	info_label.size = Vector2(get_viewport().size.x, 30)
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6, 0.9))
	info_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	info_label.add_theme_constant_override("shadow_outline_size", 2)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_container.add_child(info_label)

	# Version info
	var version_label = Label.new()
	version_label.text = "FapLand v1.0 • Handy Edition"
	version_label.position = Vector2(-460, 70)
	version_label.size = Vector2(get_viewport().size.x, 25)
	version_label.add_theme_font_size_override("font_size", 14)
	version_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8, 0.7))
	version_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	version_label.add_theme_constant_override("shadow_outline_size", 1)
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_container.add_child(version_label)


func start_background_animations():
	"""Start continuous background animations"""

	# Title pulsing animation
	if ui_elements.has("game_title"):
		var title = ui_elements["game_title"]
		title_animation_tween = create_tween()
		title_animation_tween.set_loops()
		title_animation_tween.tween_property(title, "modulate", Color(1.2, 1.2, 1.2, 1.0), 2.0)
		title_animation_tween.tween_property(title, "modulate", Color.WHITE, 2.0)

	# Start button glow animation
	if ui_elements.has("start_button"):
		var start_btn = ui_elements["start_button"]
		var glow_tween = create_tween()
		glow_tween.set_loops()
		glow_tween.tween_property(start_btn, "modulate", Color(1.15, 1.15, 1.15, 1.0), 1.5)
		glow_tween.tween_property(start_btn, "modulate", Color.WHITE, 1.5)

	# Floating emoji timer
	particle_timer = Timer.new()
	particle_timer.wait_time = 3.0
	particle_timer.timeout.connect(_on_spawn_floating_emoji)
	add_child(particle_timer)
	particle_timer.start()


func _on_spawn_floating_emoji():
	"""Spawn floating emojis periodically"""
	var emoji = Label.new()
	emoji.text = floating_emojis[current_emoji_index]
	current_emoji_index = (current_emoji_index + 1) % floating_emojis.size()

	emoji.add_theme_font_size_override("font_size", 32)
	emoji.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.8))
	emoji.add_theme_color_override("font_shadow_color", Color.BLACK)
	emoji.add_theme_constant_override("shadow_outline_size", 2)

	# Start from bottom, float up
	emoji.position = Vector2(randf() * get_viewport().size.x, get_viewport().size.y + 50)
	add_child(emoji)

	# Float up animation
	var float_tween = create_tween()
	float_tween.parallel().tween_property(emoji, "position:y", -100, 8.0)
	float_tween.parallel().tween_property(emoji, "modulate:a", 0.0, 8.0)
	float_tween.tween_callback(emoji.queue_free)


func play_entrance_animation():
	"""Play premium entrance animation for all elements"""

	# Start everything invisible
	main_container.modulate = Color.TRANSPARENT

	# Fade in background
	var bg_tween = create_tween()
	bg_tween.tween_property(main_container, "modulate", Color.WHITE, 1.5)

	# Title container entrance
	if ui_elements.has("title_container"):
		var title_container = ui_elements["title_container"]
		title_container.position.y -= 100
		title_container.modulate = Color.TRANSPARENT

		await bg_tween.finished

		var title_tween = create_tween()
		title_tween.parallel().tween_property(
			title_container, "position:y", title_container.position.y + 100, 1.0
		)
		title_tween.parallel().tween_property(title_container, "modulate", Color.WHITE, 1.0)

		await title_tween.finished

	# Menu buttons entrance (staggered)
	var buttons = ["start_button", "how_to_play_button", "exit_button"]
	for i in range(buttons.size()):
		if ui_elements.has(buttons[i]):
			var button = ui_elements[buttons[i]]
			button.modulate = Color.TRANSPARENT
			button.scale = Vector2(0.5, 0.5)

			var button_tween = create_tween()
			button_tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.6)
			button_tween.parallel().tween_property(button, "scale", Vector2(1.0, 1.0), 0.6)

			# Stagger the button animations
			await get_tree().create_timer(0.2).timeout


# Button event handlers


func _on_start_game_pressed():
	"""Handle start game button press"""
	print("🚀 Start Game pressed - transitioning to main game...")

	# Create premium button press effect
	if ui_elements.has("start_button"):
		var start_btn = ui_elements["start_button"]
		var press_tween = create_tween()
		press_tween.tween_property(start_btn, "scale", Vector2(0.95, 0.95), 0.1)
		press_tween.tween_property(start_btn, "scale", Vector2(1.0, 1.0), 0.1)

	# Show loading message
	show_premium_popup("🎮 Loading FapLand Game...", Color.GREEN)

	# Wait for button animation
	await get_tree().create_timer(0.5).timeout

	# Premium transition out
	await play_exit_animation()

	# Load main game scene - replace with your actual scene name
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_how_to_play_pressed():
	"""Handle how to play button press"""
	print("❓ How to Play pressed")

	# Create premium button press effect
	if ui_elements.has("how_to_play_button"):
		var help_btn = ui_elements["how_to_play_button"]
		var press_tween = create_tween()
		press_tween.tween_property(help_btn, "scale", Vector2(0.95, 0.95), 0.1)
		press_tween.tween_property(help_btn, "scale", Vector2(1.0, 1.0), 0.1)

	show_how_to_play_popup()


func _on_exit_pressed():
	"""Handle exit button press"""
	print("🚪 Exit pressed")

	# Create premium button press effect
	if ui_elements.has("exit_button"):
		var exit_btn = ui_elements["exit_button"]
		var press_tween = create_tween()
		press_tween.tween_property(exit_btn, "scale", Vector2(0.95, 0.95), 0.1)
		press_tween.tween_property(exit_btn, "scale", Vector2(1.0, 1.0), 0.1)

	show_premium_popup("👋 Thanks for playing FapLand!", Color.YELLOW)

	# Wait for popup then exit
	await get_tree().create_timer(1.5).timeout
	get_tree().quit()


func create_highscore_panel(parent: Control):
	"""Create highscore display panel"""

	var highscore_container = Panel.new()
	highscore_container.name = "HighscoreContainer"
	highscore_container.position = Vector2(get_viewport().size.x - 320, 320)
	highscore_container.size = Vector2(300, 300)

	# Premium highscore styling
	var highscore_style = StyleBoxFlat.new()
	highscore_style.bg_color = Color(0.05, 0.05, 0.15, 0.9)
	highscore_style.border_width_left = 3
	highscore_style.border_width_right = 3
	highscore_style.border_width_top = 3
	highscore_style.border_width_bottom = 3
	highscore_style.border_color = Color(1.0, 0.8, 0.0, 0.9)
	highscore_style.corner_radius_top_left = 20
	highscore_style.corner_radius_top_right = 20
	highscore_style.corner_radius_bottom_left = 20
	highscore_style.corner_radius_bottom_right = 20
	highscore_style.shadow_color = Color(1.0, 0.8, 0.0, 0.4)
	highscore_style.shadow_size = 12
	highscore_container.add_theme_stylebox_override("panel", highscore_style)
	parent.add_child(highscore_container)
	ui_elements["highscore_container"] = highscore_container

	# Highscore title
	var title = Label.new()
	title.text = "🏆 HIGH SCORES 🏆"
	title.position = Vector2(0, 15)
	title.size = Vector2(300, 40)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	highscore_container.add_child(title)

	# Load and display highscores
	var highscores = load_highscores()
	var best_round = get_best_round()

	# Best score display
	var best_score_label = Label.new()
	best_score_label.text = (
		"Best: Round " + str(best_round) if best_round > 0 else "Best: No scores yet"
	)
	best_score_label.position = Vector2(10, 60)
	best_score_label.size = Vector2(280, 30)
	best_score_label.add_theme_font_size_override("font_size", 16)
	best_score_label.add_theme_color_override("font_color", Color.WHITE)
	best_score_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	best_score_label.add_theme_constant_override("shadow_outline_size", 2)
	best_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	highscore_container.add_child(best_score_label)

	# Scores list
	var y_pos = 100
	for i in range(min(6, highscores.size())):
		var score = highscores[i]
		var rank_text = str(i + 1) + ". Round " + str(score["round"])

		# Add reason emoji
		var reason_emoji = "💀" if score["reason"] == "ejaculation" else "🏆"
		rank_text = reason_emoji + " " + rank_text

		var score_label = Label.new()
		score_label.text = rank_text
		score_label.position = Vector2(15, y_pos)
		score_label.size = Vector2(270, 25)
		score_label.add_theme_font_size_override("font_size", 14)

		# Color based on rank
		var score_color = (
			Color.GOLD
			if i == 0
			else Color.SILVER if i == 1 else Color(0.8, 0.5, 0.2, 1.0) if i == 2 else Color.WHITE
		)
		score_label.add_theme_color_override("font_color", score_color)
		score_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		score_label.add_theme_constant_override("shadow_outline_size", 1)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		highscore_container.add_child(score_label)

		y_pos += 30

	# No scores message
	if highscores.size() == 0:
		var no_scores = Label.new()
		no_scores.text = "🎮 Play to set your first score!"
		no_scores.position = Vector2(10, 120)
		no_scores.size = Vector2(280, 100)
		no_scores.add_theme_font_size_override("font_size", 16)
		no_scores.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6, 0.8))
		no_scores.add_theme_color_override("font_shadow_color", Color.BLACK)
		no_scores.add_theme_constant_override("shadow_outline_size", 2)
		no_scores.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_scores.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		no_scores.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		highscore_container.add_child(no_scores)

	# Clear scores button
	var clear_button = Button.new()
	clear_button.text = "🗑️ Clear Scores"
	clear_button.position = Vector2(75, 260)
	clear_button.size = Vector2(150, 35)
	clear_button.add_theme_font_size_override("font_size", 14)

	var clear_style = StyleBoxFlat.new()
	clear_style.bg_color = Color(0.6, 0.2, 0.2, 0.9)
	clear_style.corner_radius_top_left = 10
	clear_style.corner_radius_top_right = 10
	clear_style.corner_radius_bottom_left = 10
	clear_style.corner_radius_bottom_right = 10
	clear_button.add_theme_stylebox_override("normal", clear_style)
	clear_button.add_theme_color_override("font_color", Color.WHITE)
	clear_button.pressed.connect(_on_clear_scores_pressed)
	highscore_container.add_child(clear_button)


func load_highscores() -> Array:
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


func get_best_round() -> int:
	"""Get the highest round reached"""
	var highscores = load_highscores()
	if highscores.size() > 0:
		return highscores[0]["round"]
	else:
		return 0


func _on_clear_scores_pressed():
	"""Clear all highscores"""
	var file = FileAccess.open("highscores.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"scores": []}))
		file.close()
		print("🗑️ Cleared all highscores")

		# Refresh the display
		if ui_elements.has("highscore_container"):
			ui_elements["highscore_container"].queue_free()
			ui_elements.erase("highscore_container")
			create_highscore_panel(main_container)


func show_how_to_play_popup():
	"""Show premium how to play instructions"""

	# Create overlay background
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Create instructions container
	var instructions_container = get_node("HowToPlayBox")
	instructions_container.visible = true
	move_child(instructions_container, get_child_count() - 1)
	for child in instructions_container.get_children():
		child.queue_free()

	# Premium instructions styling
	var instructions_style = StyleBoxFlat.new()
	instructions_style.bg_color = Color(0.05, 0.05, 0.15, 0.98)
	instructions_style.border_width_left = 4
	instructions_style.border_width_right = 4
	instructions_style.border_width_top = 4
	instructions_style.border_width_bottom = 4
	instructions_style.border_color = Color(0.3, 0.6, 1.0, 1.0)
	instructions_style.corner_radius_top_left = 25
	instructions_style.corner_radius_top_right = 25
	instructions_style.corner_radius_bottom_left = 25
	instructions_style.corner_radius_bottom_right = 25
	instructions_style.shadow_color = Color(0.3, 0.6, 1.0, 0.6)
	instructions_style.shadow_size = 20
	instructions_container.add_theme_stylebox_override("panel", instructions_style)
	add_child(instructions_container)

	# Instructions title
	var title = Label.new()
	title.text = "🎯 HOW TO PLAY FAPLAND"
	title.position = Vector2(0, 20)
	title.size = Vector2(800, 50)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_outline_size", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions_container.add_child(title)

	# LEFT COLUMN - Game Basics
	var left_column_text = """🎮 OBJECTIVE:
Reach Round 100 without ejaculating!

🎲 GAMEPLAY:
• Click PLAY to watch video
• Roll dice when video ends
• Move forward 1-6 rounds

⏸️ PAUSES:
• Get pause tokens for videos
• Use SPACE in VLC to pause
• Press E if you ejaculate

🌟 PERKS:
• Earn perks with a chance each round
• Click perks window to use
• Get special advantages"""

	var left_column = Label.new()
	left_column.text = left_column_text
	left_column.position = Vector2(20, 80)
	left_column.size = Vector2(360, 350)
	left_column.add_theme_font_size_override("font_size", 15)
	left_column.add_theme_color_override("font_color", Color.WHITE)
	left_column.add_theme_color_override("font_shadow_color", Color.BLACK)
	left_column.add_theme_constant_override("shadow_outline_size", 2)
	left_column.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	left_column.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions_container.add_child(left_column)

	# RIGHT COLUMN - Controls & Tips
	var right_column_text = """🎬 VLC CONTROLS:
• SPACE = Pause
• R = Resync Handy
• E = Ejaculate (game over)
• Q/ESC = Quit video

💡 STRATEGY TIPS:
• Use pauses strategically
• Save perks for hard rounds
• Videos get more challenging
• Plan your perk usage
• Don't waste early pauses

🏆 WIN CONDITION:
Complete all 100 rounds!"""

	var right_column = Label.new()
	right_column.text = right_column_text
	right_column.position = Vector2(400, 80)
	right_column.size = Vector2(360, 350)
	right_column.add_theme_font_size_override("font_size", 15)
	right_column.add_theme_color_override("font_color", Color.WHITE)
	right_column.add_theme_color_override("font_shadow_color", Color.BLACK)
	right_column.add_theme_constant_override("shadow_outline_size", 2)
	right_column.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	right_column.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions_container.add_child(right_column)

	# Close button
	var close_button = Button.new()
	close_button.text = "✓ GOT IT!"
	close_button.position = Vector2(300, 440)
	close_button.size = Vector2(200, 40)
	close_button.add_theme_font_size_override("font_size", 18)

	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.1, 0.7, 0.1, 0.95)
	close_style.corner_radius_top_left = 15
	close_style.corner_radius_top_right = 15
	close_style.corner_radius_bottom_left = 15
	close_style.corner_radius_bottom_right = 15
	close_button.add_theme_stylebox_override("normal", close_style)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	instructions_container.add_child(close_button)

	# Close popup when button pressed
	close_button.pressed.connect(
		func():
			overlay.queue_free()
			instructions_container.visible = false
	)

	# Entrance animation
	overlay.modulate = Color.TRANSPARENT
	instructions_container.modulate = Color.TRANSPARENT
	instructions_container.scale = Vector2(0.3, 0.3)

	var popup_tween = create_tween()
	popup_tween.parallel().tween_property(overlay, "modulate", Color.WHITE, 0.4)
	popup_tween.parallel().tween_property(instructions_container, "modulate", Color.WHITE, 0.6)
	popup_tween.parallel().tween_property(instructions_container, "scale", Vector2(1.0, 1.0), 0.6)


func play_exit_animation():
	"""Play premium exit animation"""

	# Fade out with scale down
	var exit_tween = create_tween()
	exit_tween.parallel().tween_property(main_container, "modulate", Color.TRANSPARENT, 1.0)
	exit_tween.parallel().tween_property(main_container, "scale", Vector2(0.8, 0.8), 1.0)

	await exit_tween.finished


func show_premium_popup(message: String, color: Color = Color.YELLOW):
	"""Show premium popup message"""

	var popup_container = get_node("PopupBox")
	popup_container.visible = true
	move_child(popup_container, get_child_count() - 1)
	for child in popup_container.get_children():
		child.queue_free()

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
	#add_child(popup_container)

	var popup_label = Label.new()
	popup_label.text = message
	popup_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.add_theme_font_size_override("font_size", 20)
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
	popup_tween.tween_interval(2.0)
	popup_tween.parallel().tween_property(popup_container, "modulate", Color.TRANSPARENT, 0.8)
	popup_tween.tween_callback(func(): popup_container.visible = false)
