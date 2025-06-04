class_name EmojiParticle
extends Label

const EMOJIS = ["🎮", "🎲", "🎬", "⭐", "💎", "🔥", "✨", "🌟"]

static var current_emoji_index := 0


func _ready() -> void:
	setup()


func setup() -> void:
	text = EMOJIS[current_emoji_index]
	current_emoji_index = (current_emoji_index + 1) % EMOJIS.size()
	scale = randf_range(0.5, 1) * Vector2.ONE
	modulate.a = randf_range(0.1, 0.3)


func drift_tween() -> void:
	position = Vector2(randf() * get_viewport().size.x, randf() * get_viewport().size.y)
	var move_tween := create_tween()
	move_tween.set_loops()
	move_tween.set_ease(Tween.EASE_IN_OUT)
	move_tween.set_trans(Tween.TRANS_SINE)

	var target_pos = Vector2(position.x + randf_range(-100, 100), position.y + randf_range(-50, 50))
	var duration = randf_range(8.0, 15.0)

	move_tween.tween_property(self, "position", target_pos, duration)
	move_tween.tween_property(self, "position", position, duration)

	# Fade animation
	var fade_tween = create_tween()
	fade_tween.set_loops()
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.set_trans(Tween.TRANS_SINE)

	fade_tween.tween_property(self, "modulate:a", randf_range(0.05, 0.4), randf_range(3.0, 6.0))
	fade_tween.tween_property(self, "modulate:a", randf_range(0.1, 0.2), randf_range(3.0, 6.0))


func float_tween() -> void:
	position = Vector2(randf() * get_viewport().size.x, get_viewport().size.y + 50)
	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property(self, "position:y", -100, 8.0)
	tween.tween_property(self, "modulate:a", 0.0, 8.0)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
