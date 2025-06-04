# StartMenu.gd - Premium AAA Quality Start Menu
extends Control

# UI References
var ui_elements = {}

@onready var main_container: Control = $MainContainer


func _ready():
	print("🎮 Creating Premium FapLand Start Menu...")
	get_node("PopupBox").visible = false

	print("✅ Premium Start Menu ready!")


func show_premium_popup(message: String, color: Color = Color.YELLOW):
	"""Show premium popup message"""

	var popup_container = get_node("PopupBox")
	popup_container.visible = true
	move_child(popup_container, get_child_count() - 1)
	for child in popup_container.get_children():
		child.queue_free()

	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.02, 0.02, 0.08, 0.98)
	popup_style.border_width_left = 3
	popup_style.border_width_right = 3
	popup_style.border_width_top = 3
	popup_style.border_width_bottom = 3
	popup_style.border_color = color
	popup_style.corner_radius_top_left = 20
	popup_style.corner_radius_top_right = 20
	popup_style.corner_radius_bottom_left = 20
	popup_style.corner_radius_bottom_right = 20
	popup_style.shadow_color = Color(color.r, color.g, color.b, 0.5)
	popup_style.shadow_size = 12
	popup_container.add_theme_stylebox_override("panel", popup_style)
	#add_child(popup_container)

	var popup_label = Label.new()
	popup_label.text = message
	popup_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.add_theme_font_size_override("font_size", 20)
	popup_label.add_theme_color_override("font_color", color)
	popup_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	popup_label.add_theme_constant_override("shadow_outline_size", 3)
	popup_container.add_child(popup_label)

	# Premium popup animation
	popup_container.modulate = Color.TRANSPARENT
	popup_container.scale = Vector2(0.4, 0.4)

	var popup_tween = create_tween()
	popup_tween.parallel().tween_property(popup_container, "modulate", Color.WHITE, 0.4)
	popup_tween.parallel().tween_property(popup_container, "scale", Vector2(1.0, 1.0), 0.4)
	popup_tween.tween_interval(2.0)
	popup_tween.parallel().tween_property(popup_container, "modulate", Color.TRANSPARENT, 0.8)
	popup_tween.tween_callback(func(): popup_container.visible = false)
