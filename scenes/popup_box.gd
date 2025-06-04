extends Panel

signal done


func open(message: String, color: Color = Color.YELLOW):
	show()
	%Label.text = message
	modulate = Color(color, 0.0)
	scale = 0.4 * Vector2.ONE

	var popup_tween := create_tween()
	popup_tween.set_parallel()
	popup_tween.tween_property(self, "modulate", color, 0.4)
	popup_tween.tween_property(self, "scale", Vector2.ONE, 0.4)
	popup_tween.set_parallel(false)
	popup_tween.tween_interval(2.0)
	popup_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.8)
	popup_tween.tween_callback(hide)
	popup_tween.tween_callback(done.emit)
