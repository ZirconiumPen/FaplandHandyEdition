extends Panel

@export var overlay: Control

@onready var handy_toggle: CheckButton = %HandyToggle
@onready var connection_key_field: LineEdit = %ConnectionKeyField
@onready var app_id_field: LineEdit = %AppIDField


func open() -> void:
	overlay.show()
	show()
	var config = load_handy_config()
	handy_toggle.button_pressed = config.get("use_handy", true)
	connection_key_field.text = config.get("access_token", "")
	app_id_field.text = config.get("app_id", "")


func close() -> void:
	overlay.hide()
	hide()


func _on_cancel_button_pressed() -> void:
	close()


func _on_save_button_pressed() -> void:
	# show_premium_popup("✅ Handy configuration saved!", Color.GREEN)
	save_handy_config(connection_key_field.text, app_id_field.text)
	close()


func load_handy_config() -> Dictionary:
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


func save_handy_config(access_token: String, app_id: String) -> void:
	var file = FileAccess.open("handy_config.json", FileAccess.WRITE)
	if not file:
		return
	var config = {"use_handy": handy_toggle.button_pressed}
	config["access_token"] = access_token
	config["app_id"] = app_id
	file.store_string(JSON.stringify(config))
	file.close()
	print("💾 Saved Handy configuration")


func _on_check_button_toggled(toggled_on: bool) -> void:
	%ConnectionKey.visible = toggled_on
	%AppID.visible = toggled_on
