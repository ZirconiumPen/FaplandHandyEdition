class_name MainContainer
extends Control

const MainScene = preload("uid://c4ei5qhvpx1qf")

@onready var start_button: Button = %StartButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var exit_button: Button = %ExitButton

@onready var overlay: Control = $Overlay
@onready var handy_config_box: Panel = $HandyConfigBox
@onready var how_to_play_box: Panel = $HowToPlayBox


func _on_fullscreen_button_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_install_button_pressed() -> void:
	"""Handle install dependencies button press"""
	print("⚙️ Install Dependencies pressed")

	# Check if Python is installed first
	var python_commands = ["python", "python3", "py"]
	var python_found = false

	for python_cmd in python_commands:
		var process_id = OS.create_process(python_cmd, ["--version"])
		if process_id > 0:
			python_found = true
			break

	if not python_found:
		# show_premium_popup(
		# "❌ Python not found! Please install Python first from python.org", Color.RED
		# )
		return

	# show_premium_popup("🔄 Installing Python dependencies... This may take a moment.", Color.YELLOW)

	# Install required packages
	var packages = ["requests", "python-vlc", "keyboard"]

	for package in packages:
		print("Installing: " + package)
		var pip_process = OS.create_process("pip", ["install", package])
		# You could also try "pip3" if pip fails
		if pip_process <= 0:
			OS.create_process("pip3", ["install", package])

	await get_tree().create_timer(3.0).timeout
	# show_premium_popup("✅ Dependencies installation completed!", Color.GREEN)


func _on_handy_button_pressed() -> void:
	handy_config_box.open()


func _on_start_button_pressed() -> void:
	print("🚀 Start Game pressed - transitioning to main game...")

	var press_tween = create_tween()
	press_tween.tween_property(start_button, "scale", Vector2.ONE, 0.1).from(0.95 * Vector2.ONE)

	# Show loading message
	# show_premium_popup("🎮 Loading FapLand Game...", Color.GREEN)

	# Wait for button animation
	await get_tree().create_timer(0.5).timeout

	# Premium transition out
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

	var press_tween = create_tween()
	press_tween.tween_property(exit_button, "scale", Vector2(0.95, 0.95), 0.1)
	press_tween.tween_property(exit_button, "scale", Vector2(1.0, 1.0), 0.1)

	# show_premium_popup("👋 Thanks for playing FapLand!", Color.YELLOW)

	# Wait for popup then exit
	await get_tree().create_timer(1.5).timeout
	get_tree().quit()


func play_exit_animation():
	# Fade out with scale down
	var exit_tween = create_tween()
	exit_tween.set_parallel()
	exit_tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.0)
	exit_tween.tween_property(self, "scale", 0.8 * Vector2.ONE, 1.0)

	await exit_tween.finished
