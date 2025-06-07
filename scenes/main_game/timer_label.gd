class_name TimerLabel
extends Label

@onready var start_time := Time.get_unix_time_from_system()


func _ready() -> void:
	text = "Session: 00:00"


func _on_debouncer_timeout() -> void:
	var current_time = Time.get_unix_time_from_system()
	var elapsed_time = current_time - start_time

	@warning_ignore("INTEGER_DIVISION")
	var hours = int(elapsed_time) / 3600
	@warning_ignore("INTEGER_DIVISION")
	var minutes = (int(elapsed_time) / 60) % 60
	var seconds = int(elapsed_time) % 60

	if hours > 0:
		text = "Session: %02d:%02d:%02d" % [hours, minutes, seconds]
	else:
		text = "Session: %02d:%02d" % [minutes, seconds]
