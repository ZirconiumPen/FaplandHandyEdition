class_name ComingUpBox
extends Panel

const PATH_TO_SPRITESHEETS = "res://media/"
const COLS = 10
const FRAME_RATE = 24
const FRAME_WIDTH = 320
const FRAME_HEIGHT = 180

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var fallback_label: Label = %FallbackLabel


func open(next_round_num: int) -> void:
	show()
	_load_spritesheet(next_round_num)
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


func _load_spritesheet(num: int) -> void:
	animated_sprite.hide()
	var image = Image.new()
	var error := image.load("%s%s.png" % [PATH_TO_SPRITESHEETS, num])
	if error != OK:
		fallback_label.text = "🎬 Round %s" % num
		fallback_label.show()
		print("❌ Failed to load sprite frames, using fallback")
		return

	var texture := ImageTexture.new()
	texture.set_image(image)
	var sprite_frames := SpriteFrames.new()
	sprite_frames.set_animation_speed("default", FRAME_RATE)
	@warning_ignore("INTEGER_DIVISION")
	var rows: int = texture.get_height() / FRAME_HEIGHT

	for row in rows:
		for col in COLS:
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.region = Rect2(
				col * FRAME_WIDTH, row * FRAME_HEIGHT, FRAME_WIDTH, FRAME_HEIGHT
			)
			sprite_frames.add_frame("default", atlas_texture)
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.show()
	animated_sprite.play()
	fallback_label.hide()
