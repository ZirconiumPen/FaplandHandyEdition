class_name MainContainer
extends Control


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
