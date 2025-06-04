extends Panel

@export var overlay: Control


func open() -> void:
	overlay.show()
	show()
	# Entrance animation
	overlay.modulate = Color.TRANSPARENT
	modulate = Color.TRANSPARENT
	scale = Vector2(0.3, 0.3)

	var popup_tween = create_tween()
	popup_tween.set_parallel()
	popup_tween.tween_property(overlay, "modulate", Color.WHITE, 0.4)
	popup_tween.tween_property(self, "modulate", Color.WHITE, 0.6)
	popup_tween.tween_property(self, "scale", Vector2.ONE, 0.6)


func close() -> void:
	hide()
	overlay.hide()


func _on_close_button_pressed() -> void:
	close()
