class_name Message
extends RefCounted

var text: String
var color: Color


func _init(new_text: String, new_color: Color = Color.WHITE) -> void:
	text = new_text
	color = new_color
