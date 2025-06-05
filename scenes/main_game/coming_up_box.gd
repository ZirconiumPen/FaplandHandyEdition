class_name ComingUpBox
extends Panel

const PATH_TO_TRES = "res://sprites/tres_files/"

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var fallback_label: Label = %FallbackLabel


func open(next_round_num: int) -> void:
	show()

	var sprite_frames := load("%s%s.tres" % [PATH_TO_TRES, next_round_num]) as SpriteFrames

	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.animation = "animation"
		animated_sprite.scale = 1.25 * Vector2.ONE  # Same scale as your existing setup
		animated_sprite.play()
		print("🎬 Showing hardcoded animated sprite for round %s" % next_round_num)
	else:
		fallback_label.text = "🎬 Round %s" % next_round_num
		print("❌ Failed to load sprite frames, using fallback")

	modulate = Color.TRANSPARENT
	scale = 0.3 * Vector2.ONE

	var entrance_tween := create_tween()
	entrance_tween.set_parallel()
	entrance_tween.tween_property(self, "modulate", Color.WHITE, 0.8)
	entrance_tween.tween_property(self, "scale", Vector2.ONE, 0.8)

	# Pulsing animation
	await entrance_tween.finished
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(self, "modulate", Color(1.15, 1.15, 1.15), 1.2)
	pulse_tween.tween_property(self, "modulate", Color.WHITE, 1.2)

	print("🎯 Showing 'Coming Up Next' for Round ", next_round_num)


func close():
	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	fade_tween.tween_callback(hide)
	print("👋 Hiding 'Coming Up Next' display")
