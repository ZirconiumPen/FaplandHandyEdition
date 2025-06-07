class_name CountdownBar
extends ProgressBar

signal timeout

@export var countdown_time: float = 30.0

@onready var timer: Timer = $Timer


func _ready() -> void:
	min_value = 0
	max_value = countdown_time
	timer.wait_time = countdown_time
	timer.timeout.connect(timeout.emit)
	timer.timeout.connect(hide)
	hide()


func _process(_delta: float) -> void:
	if timer.is_stopped():
		return
	value = timer.time_left


func start(time: float = countdown_time) -> void:
	show()
	timer.start(time)


func stop() -> void:
	timer.stop()
	hide()
