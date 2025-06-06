class_name TitleScreen
extends Control

const MainScene = preload("uid://c4ei5qhvpx1qf")

@onready var title_container: Control = %TitleContainer
@onready var game_title: Label = %GameTitle

@onready var menu_container: Container = %MenuContainer
@onready var start_button: Button = %StartButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var exit_button: Button = %ExitButton

@onready var overlay: Control = $Overlay
@onready var handy_config_box: Panel = $HandyConfigBox
@onready var how_to_play_box: Panel = $HowToPlayBox
@onready var popup_box: Panel = $PopupBox


func _ready() -> void:
	# Force solid black background
	RenderingServer.set_default_clear_color(Color.BLACK)

	# Title pulsing animation
	var title_animation_tween := create_tween()
	title_animation_tween.set_loops()
	# WARN: colors above 1.0 don't seem to do anything
	title_animation_tween.tween_property(game_title, "modulate", Color(1.2, 1.2, 1.2, 1.0), 2.0)
	title_animation_tween.tween_property(game_title, "modulate", Color.WHITE, 2.0)

	# Start button glow animation
	var glow_tween := create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(start_button, "modulate", Color(1.15, 1.15, 1.15, 1.0), 1.5)
	glow_tween.tween_property(start_button, "modulate", Color.WHITE, 1.5)

	play_entrance_animation()


func play_entrance_animation() -> void:
	# Start everything invisible
	modulate = Color.TRANSPARENT

	# Fade in background
	var bg_tween := create_tween()
	bg_tween.tween_property(self, "modulate", Color.WHITE, 1.5)

	await bg_tween.finished

	# Title container entrance
	title_container.position.y -= 100
	title_container.modulate = Color.TRANSPARENT

	var title_tween := create_tween()
	title_tween.set_parallel()
	title_tween.tween_property(title_container, "position:y", 100, 1.0).as_relative()
	title_tween.tween_property(title_container, "modulate", Color.WHITE, 1.0)

	await title_tween.finished

	# Menu buttons entrance (staggered)
	for button: Button in menu_container.get_children():
		button.modulate = Color.TRANSPARENT
		button.scale = Vector2(0.5, 0.5)

		var button_tween = create_tween()
		button_tween.set_parallel()
		button_tween.tween_property(button, "modulate", Color.WHITE, 0.6)
		button_tween.tween_property(button, "scale", Vector2.ONE, 0.6)

		# Stagger the button animations
		await get_tree().create_timer(0.2).timeout


func play_exit_animation():
	# Fade out with scale down
	var exit_tween = create_tween()
	exit_tween.set_parallel()
	exit_tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.0)
	exit_tween.tween_property(self, "scale", 0.8 * Vector2.ONE, 1.0)

	await exit_tween.finished


func _on_fullscreen_button_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_install_button_pressed() -> void:
	"""Handle install dependencies button press"""
	print("⚙️ Install Dependencies pressed")

	# Check if Python is installed first
	var python_commands = ["py", "python", "python3"]
	var python_found = false

	for python_cmd in python_commands:
		var process_id = OS.create_process(python_cmd, ["--version"])
		if process_id > 0:
			python_found = true
			break

	if not python_found:
		popup_box.open("❌ Python not found! Please install Python first from python.org", Color.RED)
		return

	popup_box.open("🔄 Installing Python dependencies... This may take a moment.", Color.YELLOW)

	# Install required packages
	var packages = ["requests", "python-vlc", "keyboard", "pandas"]

	for package in packages:
		var pip_commands = ["py", "-m", "pip", "install", package]
		var pip_process = OS.create_process(pip_commands[0], pip_commands.slice(1))
		if pip_process <= 0:
			OS.create_process("pip", ["install", package])

	await get_tree().create_timer(3.0).timeout
	popup_box.open("✅ Dependencies installation completed!", Color.GREEN)


func _on_handy_button_pressed() -> void:
	handy_config_box.open()


func _on_start_button_pressed() -> void:
	print("🚀 Start Game pressed - transitioning to main game...")

	var press_tween = create_tween()
	press_tween.tween_property(start_button, "scale", Vector2.ONE, 0.1).from(0.95 * Vector2.ONE)

	popup_box.open("🎮 Loading FapLand Game...", Color.GREEN)
	# TODO: start loading here

	await popup_box.done

	await play_exit_animation()

	get_tree().change_scene_to_packed(MainScene)


func _on_how_to_play_button_pressed() -> void:
	print("❓ How to Play pressed")

	var press_tween = create_tween()
	press_tween.tween_property(how_to_play_button, "scale", Vector2.ONE, 0.1).from(
		0.95 * Vector2.ONE
	)

	how_to_play_box.open()


func _on_exit_button_pressed() -> void:
	print("🚪 Exit pressed")

	var press_tween := create_tween()
	press_tween.tween_property(exit_button, "scale", 0.95 * Vector2.ONE, 0.1)
	press_tween.tween_property(exit_button, "scale", Vector2.ONE, 0.1)

	popup_box.open("👋 Thanks for playing FapLand!", Color.YELLOW)

	await popup_box.done
	get_tree().quit()


func _on_randomize_button_pressed() -> void:
	popup_box.open("🔁 Randomizing rounds... Please wait.", Color.CYAN)

	# Execute the Python script
	var output = []
	var python_commands = ["py", "python", "python3"]
	var success = false

	for python_cmd in python_commands:
		var result = OS.execute(python_cmd, ["./scripts/randomize_rounds.py"], output, true)
		if result != 0:
			continue
		success = true
		popup_box.open("✅️ Rounds randomized successfully!", Color.GREEN)
		if not output.is_empty():
			print("Script output: ", output)

	if not success:
		popup_box.open(
			"❌️ Failed to execute randomize script. Check console for details.", Color.RED
		)
		print("❌️ Failed to execute randomize_rounds.py with any Python command")
		print("Script output: ", output)
