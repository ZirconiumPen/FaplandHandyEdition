class_name VictoryPopup
extends Control

@onready var victory_container: Panel = %VictoryContainer
@onready var victory_label: Label = %VictoryLabel


func open() -> void:
	show()

	victory_container.modulate = Color.TRANSPARENT
	victory_container.scale = 0.2 * Vector2.ONE

	var victory_tween := create_tween()
	victory_tween.set_parallel()
	victory_tween.tween_property(victory_container, "modulate", Color.WHITE, 1.0)
	victory_tween.tween_property(victory_container, "scale", Vector2.ONE, 1.0)

	# Premium fireworks effect
	for i in range(15):
		add_child(Fireworks.new())
		await get_tree().create_timer(0.15).timeout  # Stagger fireworks

	# Premium pulsing victory text
	var pulse_tween := create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(victory_label, "scale", 1.15 * Vector2.ONE, 1.0)
	pulse_tween.tween_property(victory_label, "scale", Vector2.ONE, 1.0)

	# Exit after victory
	await get_tree().create_timer(5.0).timeout
	get_tree().quit()
