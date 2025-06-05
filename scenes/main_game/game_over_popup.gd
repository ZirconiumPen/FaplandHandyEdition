class_name GameOverPopup
extends Control

@onready var overlay: Control = $Overlay
@onready var game_over_container: Panel = $GameOverContainer
@onready var game_over_label: Label = %GameOverLabel
@onready var failure_label: Label = %FailureLabel


func open(current_round: int) -> void:
	failure_label.text = "You reached round %s before failing the challenge!" % current_round

	overlay.modulate = Color.TRANSPARENT
	game_over_container.modulate = Color.TRANSPARENT
	game_over_container.scale = 0.2 * Vector2.ONE

	var entrance_tween := create_tween()
	entrance_tween.set_parallel()
	entrance_tween.tween_property(overlay, "modulate", Color.WHITE, 0.6)
	entrance_tween.tween_property(game_over_container, "modulate", Color.WHITE, 1.0)
	entrance_tween.tween_property(game_over_container, "scale", Vector2.ONE, 1.0)

	var shake_tween := create_tween()
	shake_tween.set_loops(8)
	shake_tween.tween_property(game_over_container, "position", Vector2(8, 0), 0.04).as_relative()
	shake_tween.tween_property(game_over_container, "position", Vector2(-8, 0), 0.04).as_relative()
	shake_tween.tween_property(game_over_container, "position", game_over_container.position, 0.04)

	# Premium pulsing game over text
	var pulse_tween := create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(game_over_label, "modulate", Color.WHITE, 0.5)
	pulse_tween.tween_property(game_over_label, "modulate", Color.RED, 0.5)
