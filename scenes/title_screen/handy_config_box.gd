extends Panel

const FIRMWARE_4 = 0
const FIRMWARE_3 = 1

@export var overlay: Control

@onready var firmware_dropdown: OptionButton = %FirmwareDropdown
@onready var connection_key_field: LineEdit = %ConnectionKeyField
@onready var app_id_field: LineEdit = %AppIDField


func open() -> void:
	overlay.show()
	show()
	var config = load_handy_config()
	connection_key_field.text = config.get("access_token", "")
	app_id_field.text = config.get("app_id", "")
	if config.get("firmware", 4) == 3:
		firmware_dropdown.selected = FIRMWARE_3
	else:
		firmware_dropdown.selected = FIRMWARE_4


func close() -> void:
	overlay.hide()
	hide()


func _on_cancel_button_pressed() -> void:
	close()


func _on_save_button_pressed() -> void:
	# show_premium_popup("✅ Handy configuration saved!", Color.GREEN)
	save_handy_config(
		connection_key_field.text,
		app_id_field.text,
		3 if firmware_dropdown.selected == FIRMWARE_3 else 4
	)
	close()


func load_handy_config() -> Dictionary:
	"""Load Handy configuration from file"""
	if not FileAccess.file_exists("handy_config.json"):
		return {}

	var file = FileAccess.open("handy_config.json", FileAccess.READ)
	if not file:
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		return {}

	return json.data


func save_handy_config(access_token: String, app_id: String, firmware: int = 4) -> void:
	"""Save Handy configuration to file"""
	var file = FileAccess.open("handy_config.json", FileAccess.WRITE)
	if not file:
		return
	var config = {"access_token": access_token, "app_id": app_id, "firmware": firmware}
	file.store_string(JSON.stringify(config))
	file.close()
	print("💾 Saved Handy configuration")
