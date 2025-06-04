class_name Emojis
extends CanvasGroup

const EmojiParticleScene = preload("uid://cu1vpt1sr4fs2")

@export var num_particles: int = 20

@onready var timer: Timer = $Timer


func _ready() -> void:
	for i in num_particles:
		var particle: EmojiParticle = EmojiParticleScene.instantiate()
		add_child(particle)
		particle.drift_tween()


func _on_timer_timeout() -> void:
	var particle = EmojiParticleScene.instantiate()
	add_child(particle)
	particle.float_tween()
