# PerkSystem.gd - Standalone Perk System for FapLand
extends RefCounted
class_name PerkSystem

signal perk_earned(perk_id: String)
signal perk_used(perk_id: String)
signal ui_update_needed

# Perk System Variables
var perks_inventory = []
var max_perks_inventory = 5
var active_perks = {}
var perk_chance_a = 10
var perk_chance_b = 15
var c1 = false
var c2 = false
var c3 = false

# Reference to main game (passed in constructor)
var main_game: Control

# Perk definitions
var perk_data = {
	# S Class Perks
	"skip_round": {"name": "Skip Round", "class": "S", "icon": "⏭️", "color": Color.GOLD},
	"lucky_7": {"name": "Lucky 7", "class": "S", "icon": "🍀", "color": Color.GOLD},
	# A Class Perks
	"reroll_dice": {"name": "Reroll Dice", "class": "A", "icon": "🔄", "color": Color.PURPLE},
	"huge_dice": {"name": "Huge Dice", "class": "A", "icon": "🎲", "color": Color.PURPLE},
	# B Class Perks
	"pause_extension": {"name": "Pause Extension", "class": "B", "icon": "⏰", "color": Color.CYAN},
	"bonus_pauses": {"name": "Bonus Pauses", "class": "B", "icon": "⏸️", "color": Color.CYAN}
}


func _init(game_reference: Control):
	main_game = game_reference
	print("✨ Perk System initialized")


func get_perk_display_text() -> String:
	"""Generate display text for perk inventory"""
	var text = "🌟 PERKS (" + str(perks_inventory.size()) + "/" + str(max_perks_inventory) + ")\n"

	if perks_inventory.size() == 0:
		text += "No perks"
	else:
		for i in range(perks_inventory.size()):
			var perk_id = perks_inventory[i]
			var perk = perk_data[perk_id]
			text += perk.icon + " " + perk.name
			if i < perks_inventory.size() - 1:
				text += "\n"

	return text


func check_perk_rewards(current_round: int):
	"""Check for perk rewards after completing a round"""
	# S Class milestone rewards
	if (
		(current_round >= 25 and not c1)
		or (current_round >= 50 and not c2)
		or (current_round >= 75 and not c3)
	):
		if current_round >= 25:
			c1 = true
		if current_round >= 50:
			c2 = true
		if current_round >= 75:
			c3 = true
		var s_class_perks = ["skip_round", "lucky_7"]
		var random_s_perk = s_class_perks[randi() % s_class_perks.size()]
		add_perk(random_s_perk)
		show_perk_earned_popup(random_s_perk)
		return

	# A Class random chance (10%)
	if randi() % 100 < perk_chance_a:
		var a_class_perks = ["reroll_dice", "huge_dice"]
		var random_a_perk = a_class_perks[randi() % a_class_perks.size()]
		add_perk(random_a_perk)
		show_perk_earned_popup(random_a_perk)
		return

	# B Class random chance (20%)
	if randi() % 100 < perk_chance_b:
		var b_class_perks = ["pause_extension", "bonus_pauses"]
		var random_b_perk = b_class_perks[randi() % b_class_perks.size()]
		add_perk(random_b_perk)
		show_perk_earned_popup(random_b_perk)


func add_perk(perk_id: String):
	"""Add a perk to inventory, removing oldest if at max capacity"""
	if perks_inventory.size() >= max_perks_inventory:
		var removed_perk = perks_inventory.pop_front()
		print("🗑️ Removed oldest perk: ", perk_data[removed_perk].name)
		main_game.show_aaa_popup(
			"⚠️ Perk inventory full! Lost: " + perk_data[removed_perk].name, Color.ORANGE
		)

	perks_inventory.append(perk_id)
	print("✨ Added perk: ", perk_data[perk_id].name)

	perk_earned.emit(perk_id)
	ui_update_needed.emit()


func show_perk_earned_popup(perk_id: String):
	"""Show premium popup when perk is earned"""
	var perk = perk_data[perk_id]
	var message = "✨ PERK EARNED! " + perk.icon + " " + perk.name + " [" + perk.class + " Class]"
	main_game.show_aaa_popup(message, perk.color)


func show_perk_selection_popup():
	"""Show popup for selecting which perk to use"""
	# Remove existing popup if any
	if main_game.ui_elements.has("perk_popup"):
		main_game.ui_elements["perk_popup"].queue_free()
		main_game.ui_elements.erase("perk_popup")

	# Create perk selection popup
	var popup_container = Panel.new()
	popup_container.name = "PerkPopup"
	popup_container.position = Vector2(400, 200)
	popup_container.size = Vector2(400, 60 + (perks_inventory.size() * 50))

	# Premium popup style
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.02, 0.02, 0.08, 0.98)
	popup_style.border_width_left = 3
	popup_style.border_width_right = 3
	popup_style.border_width_top = 3
	popup_style.border_width_bottom = 3
	popup_style.border_color = Color.MAGENTA
	popup_style.corner_radius_top_left = 20
	popup_style.corner_radius_top_right = 20
	popup_style.corner_radius_bottom_left = 20
	popup_style.corner_radius_bottom_right = 20
	popup_style.shadow_color = Color(1.0, 0.0, 1.0, 0.5)
	popup_style.shadow_size = 15
	popup_container.add_theme_stylebox_override("panel", popup_style)
	main_game.add_child(popup_container)

	main_game.ui_elements["perk_popup"] = popup_container

	# Title
	var title_label = Label.new()
	title_label.text = "✨ SELECT PERK TO USE ✨"
	title_label.position = Vector2(0, 10)
	title_label.size = Vector2(400, 30)
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color.MAGENTA)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_container.add_child(title_label)

	# Create perk buttons
	for i in range(perks_inventory.size()):
		var perk_id = perks_inventory[i]
		var perk = perk_data[perk_id]

		var perk_button = Button.new()
		perk_button.text = perk.icon + " " + perk.name + " [" + perk.class + "]"
		perk_button.position = Vector2(20, 50 + (i * 50))
		perk_button.size = Vector2(360, 40)
		perk_button.add_theme_font_size_override("font_size", 16)
		perk_button.add_theme_color_override("font_color", Color.WHITE)

		# Style button with perk class color
		var button_style = StyleBoxFlat.new()
		button_style.bg_color = Color(
			perk.color.r * 0.3, perk.color.g * 0.3, perk.color.b * 0.3, 0.9
		)
		button_style.border_width_left = 2
		button_style.border_width_right = 2
		button_style.border_width_top = 2
		button_style.border_width_bottom = 2
		button_style.border_color = perk.color
		button_style.corner_radius_top_left = 10
		button_style.corner_radius_top_right = 10
		button_style.corner_radius_bottom_left = 10
		button_style.corner_radius_bottom_right = 10
		perk_button.add_theme_stylebox_override("normal", button_style)

		# Connect button signal
		perk_button.pressed.connect(func(): use_perk(perk_id, i))
		popup_container.add_child(perk_button)

	# Close button
	var close_button = Button.new()
	close_button.text = "❌ CLOSE"
	close_button.position = Vector2(150, popup_container.size.y - 35)
	close_button.size = Vector2(100, 25)
	close_button.pressed.connect(close_perk_popup)
	popup_container.add_child(close_button)


func close_perk_popup():
	"""Close the perk selection popup"""
	if main_game.ui_elements.has("perk_popup"):
		main_game.ui_elements["perk_popup"].queue_free()
		main_game.ui_elements.erase("perk_popup")


func use_perk(perk_id: String, inventory_index: int):
	"""Use a perk and remove it from inventory"""
	var perk = perk_data[perk_id]
	print("🎯 Using perk: ", perk.name)

	# Remove perk from inventory
	print(main_game.ui_elements["roll_button"])
	if (
		(perk_id == "skip_round" or perk_id == "reroll_dice")
		and main_game.ui_elements.has("roll_button")
		and not main_game.ui_elements["roll_button"].disabled
	):
		main_game.show_aaa_popup("❌ Roll the dice first!", Color.RED)
		close_perk_popup()
		return

	# Check if Lucky 7 is being used after dice have been rolled
	if (
		perk_id == "lucky_7"
		and main_game.ui_elements.has("roll_button")
		and main_game.ui_elements["roll_button"].disabled
	):
		main_game.show_aaa_popup("❌ Lucky 7 must be used before rolling dice!", Color.RED)
		close_perk_popup()
		return
	perks_inventory.remove_at(inventory_index)

	# Apply perk effect
	apply_perk_effect(perk_id)

	# Close popup and emit signals
	close_perk_popup()
	perk_used.emit(perk_id)
	ui_update_needed.emit()

	main_game.show_aaa_popup("🎯 Used: " + perk.icon + " " + perk.name, perk.color)


func apply_perk_effect(perk_id: String):
	"""Apply the effect of the used perk"""
	match perk_id:
		"skip_round":
			apply_skip_round()
		"lucky_7":
			apply_lucky_7()
		"reroll_dice":
			apply_reroll_dice()
		"huge_dice":
			apply_huge_dice()
		"pause_extension":
			apply_pause_extension()
		"bonus_pauses":
			apply_bonus_pauses()


# Perk effect functions
func apply_skip_round():
	# Hide the "Coming Up Next" animation
	main_game.hide_coming_up_next()

	# Stop and clean up the countdown timer
	main_game.cleanup_countdown_timer()

	# Update UI and show popup
	main_game.update_all_ui_animated()
	main_game.show_aaa_popup("⏭️ Skipped to Round " + str(main_game.current_round), Color.GOLD)

	# Call the video completion logic to set up the next round properly
	main_game.on_video_completed()


func apply_lucky_7():
	active_perks["lucky_7"] = 1
	main_game.show_aaa_popup("🍀 Next roll will be 7!", Color.GOLD)


func apply_reroll_dice():
	main_game.cleanup_countdown_timer()
	main_game.hide_coming_up_next()

	main_game.current_round = main_game.previous_round

	if main_game.ui_elements.has("roll_button"):
		main_game.ui_elements["roll_button"].disabled = false

		# Premium roll button activation animation
		var activate_tween = main_game.create_tween()
		activate_tween.tween_property(
			main_game.ui_elements["roll_button"], "modulate", Color.WHITE, 0.4
		)
		activate_tween.tween_property(
			main_game.ui_elements["roll_button"], "scale", Vector2(1.08, 1.08), 0.3
		)
		activate_tween.tween_property(
			main_game.ui_elements["roll_button"], "scale", Vector2(1.0, 1.0), 0.3
		)

		# Add premium glow effect
		var glow_tween = main_game.create_tween()
		glow_tween.set_loops()
		glow_tween.tween_property(
			main_game.ui_elements["roll_button"], "modulate", Color(1.3, 1.3, 1.3, 1.0), 1.2
		)
		glow_tween.tween_property(
			main_game.ui_elements["roll_button"], "modulate", Color.WHITE, 1.2
		)

	if main_game.ui_elements.has("play_button"):
		main_game.ui_elements["play_button"].disabled = true
		main_game.ui_elements["play_button"].text = "▶ PLAY"
		main_game.ui_elements["play_button"].modulate = Color(0.6, 0.6, 0.6, 1.0)

	main_game.update_all_ui_animated()

	main_game.show_aaa_popup("🔄 You can reroll the dice!", Color.PURPLE)


func apply_huge_dice():
	active_perks["huge_dice"] = 2  # 2 rounds remaining
	main_game.dice_min = 1
	main_game.dice_max = 10
	main_game.show_aaa_popup("🎲 Huge dice for 2 rounds! (1-10)", Color.PURPLE)


func apply_pause_extension():
	active_perks["pause_extension"] = 3
	main_game.pause_time = 10
	main_game.show_aaa_popup("⏰ Pause duration doubled for 3 rounds!", Color.CYAN)


func get_active_perks_display_text() -> String:
	"""Generate display text for active perks"""
	var text = "⚡\nActive Perks\n"

	if active_perks.size() == 0:
		text += "None"
	else:
		var perk_texts = []
		for perk_id in active_perks.keys():
			var perk = perk_data[perk_id]
			var rounds_left = active_perks[perk_id]
			if typeof(rounds_left) == TYPE_INT and rounds_left > 1:
				perk_texts.append(perk.icon + " " + str(rounds_left) + "R")
			else:
				perk_texts.append(perk.icon + " Active")
		text += "\n".join(perk_texts)

	return text


func update_perk_timers():
	"""Update perk timers (call this each round)"""
	var perks_to_remove = []

	for perk_id in active_perks.keys():
		active_perks[perk_id] -= 1
		if active_perks[perk_id] <= 0:
			perks_to_remove.append(perk_id)

	# Remove expired perks
	for perk_id in perks_to_remove:
		active_perks.erase(perk_id)
		var perk = perk_data[perk_id]
		main_game.show_aaa_popup("⏳ " + perk.icon + " " + perk.name + " expired", Color.GRAY)

		# Reset effects
		if perk_id == "huge_dice":
			main_game.dice_min = 1
			main_game.dice_max = 6
		elif perk_id == "pause_extension":
			main_game.pause_time = 5


func apply_bonus_pauses():
	main_game.pause_count += 3
	main_game.show_aaa_popup("⏸️ +3 bonus pauses added!", Color.CYAN)


# Helper functions for main game to check perk states
func has_active_perk(perk_id: String) -> bool:
	return active_perks.has(perk_id)


func consume_active_perk(perk_id: String):
	if active_perks.has(perk_id):
		active_perks.erase(perk_id)
