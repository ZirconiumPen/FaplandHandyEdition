extends Panel

@export var max_rounds: int = 100
var water_animation_tween: Tween
var current_round: int = 1:
	set(value):
		current_round = value
		if not is_node_ready():
			await ready
		progress_text.text = "Round %s / %s" % [current_round, max_rounds]
		var progress_ratio = float(current_round) / float(max_rounds)
		var target_width = max(1, progress_ratio * 784)  # 784 is the full progress bar width, minimum 1px

		# Premium smooth water progress animation
		if water_animation_tween:
			water_animation_tween.kill()
		water_animation_tween = create_tween()
		water_animation_tween.tween_property(water_progress, "size:x", target_width, 1.5)

		# Premium color transition based on progress (water style)
		var base_water_color = Color(0.2, 0.6, 1.0, 0.8).lerp(
			Color(1.0, 0.3, 0.2, 0.8), progress_ratio
		)
		# FIXME: setting color in code
		water_progress.get_theme_stylebox("normal").bg_color = base_water_color

@onready var progress_text: Label = %ProgressText
@onready var water_progress: Panel = %WaterProgress


func _on_ripple_timer_timeout() -> void:
	"""Animate water ripples using StyleBoxFlat color modulation"""
	var time = Time.get_ticks_msec() * 0.001  # Convert milliseconds to seconds

	# Create ripple effect using sine waves
	var ripple1 = sin(time * 3.0) * 0.1 + 1.0
	var ripple2 = sin(time * 4.5 + 1.5) * 0.08 + 1.0
	var ripple3 = sin(time * 2.0 + 3.0) * 0.05 + 1.0

	var combined_ripple = ripple1 * ripple2 * ripple3

	# Apply ripple to color brightness and alpha
	var base_color = Color(0.2, 0.6, 1.0, 0.8)
	var rippled_color = Color(
		base_color.r * combined_ripple,
		base_color.g * combined_ripple,
		base_color.b * (1.0 + sin(time * 5.0) * 0.15),  # Extra blue ripple
		base_color.a * (0.7 + sin(time * 2.5) * 0.15)  # Alpha wave
	)
	water_progress.get_theme_stylebox("normal").bg_color = rippled_color
