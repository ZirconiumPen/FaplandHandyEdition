class_name NotificationTray
extends PanelContainer

@export var message_duration: float = 2.5
@export var fade_duration: float = 0.4

var message_queue: Array[Message]
var is_showing: bool = false

@onready var label: Label = $Label


func _ready() -> void:
	label.modulate = Color.TRANSPARENT


func push_message(msg: Message) -> void:
	message_queue.append(msg)
	if not is_showing:
		_show_next_message()


func _show_next_message() -> void:
	if message_queue.is_empty():
		return
	pivot_offset = size / 2
	is_showing = true
	var next_msg: Message = message_queue.pop_front()
	label.text = next_msg.text

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate", next_msg.color, fade_duration)
	tween.parallel().tween_property(label, "modulate", Color.WHITE, fade_duration)
	tween.parallel().tween_property(self, "scale", 1.1 * Vector2.ONE, fade_duration)
	tween.tween_property(self, "scale", Vector2.ONE, fade_duration)

	tween.tween_interval(message_duration)

	tween.tween_property(self, "modulate", Color.WHITE, fade_duration)
	tween.parallel().tween_property(label, "modulate", Color.TRANSPARENT, fade_duration)

	tween.tween_callback(func() -> void: is_showing = false)
	tween.tween_callback(_show_next_message)
