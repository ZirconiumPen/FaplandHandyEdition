class_name Fireworks
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

	add_theme_color_override(
		"font_color",
		[Color.GOLD, Color.RED, Color.BLUE, Color.GREEN, Color.PURPLE, Color.CYAN][
			current_emoji_index % 6
		]
	)
	position = Vector2(randf() * get_viewport().size.x, randf() * get_viewport().size.y)

	# Premium firework animation
	var firework_tween = create_tween()
	firework_tween.set_parallel()
	(
		firework_tween
		. tween_property(
			self, "position", Vector2(randf_range(-250, 250), randf_range(-250, 250)), 2.5
		)
		. as_relative()
	)
	firework_tween.tween_property(self, "modulate", Color.TRANSPARENT, 2.5)
	firework_tween.tween_property(self, "scale", 2.5 * Vector2.ONE, 2.5)
	firework_tween.set_parallel(false)
	firework_tween.tween_callback(queue_free)
