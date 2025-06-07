class_name ActionButton
extends Control
# Container that dynamically switches between different buttons.

signal play_pressed
signal roll_pressed

@onready var play_button: Button = %PlayButton
@onready var roll_button: Button = %RollButton


func switch_to_play() -> void:
	play_button.show()
	roll_button.hide()
	play_button.disabled = false
	play_button.text = "▶ PLAY"
	play_button.modulate = Color.WHITE

	var button_tween := create_tween()
	button_tween.set_loops()
	button_tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.3), 1.2)
	button_tween.tween_property(self, "modulate", Color.WHITE, 1.2)


func switch_to_roll() -> void:
	play_button.hide()
	roll_button.show()
	roll_button.disabled = false
	roll_button.text = "🎲 ROLL DICE"

	var activate_tween := create_tween()
	activate_tween.tween_property(self, "modulate", Color.WHITE, 0.4)
	activate_tween.tween_property(self, "scale", 1.08 * Vector2.ONE, 0.3)
	activate_tween.tween_property(self, "scale", Vector2.ONE, 0.3)

	var glow_tween := create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.3), 1.2)
	glow_tween.tween_property(self, "modulate", Color.WHITE, 1.2)


func _on_play_button_pressed() -> void:
	play_button.disabled = true
	play_button.text = "🎬 PLAYING..."

	var press_tween = create_tween()
	press_tween.tween_property(self, "scale", 0.92 * Vector2.ONE, 0.1)
	press_tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	press_tween.tween_property(self, "modulate", Color(0.6, 0.6, 0.6), 0.3)

	roll_button.disabled = true
	play_pressed.emit()


func _on_roll_button_pressed() -> void:
	roll_button.disabled = true
	roll_button.text = "🎲 ROLLING..."
	roll_pressed.emit()
