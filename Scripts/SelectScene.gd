extends CanvasLayer


var num_of_slots = 6

enum Options { FIRST_SLOT, SECOND_SLOT, THIRD_SLOT, FOURTH_SLOT, FIFTH_SLOT, SIXTH_SLOT }
var selected_option: int = Options.FIRST_SLOT

@onready var options: Dictionary = {
	Options.FIRST_SLOT: $FirstPokemonSlot,
	Options.SECOND_SLOT: $SecondPokemonSlot,
	Options.THIRD_SLOT: $ThirdPokemonSlot,
	Options.FOURTH_SLOT: $FourthPokemonSlot,
	Options.FIFTH_SLOT: $FifthPokemonSlot,
	Options.SIXTH_SLOT: $SixthPokemonSlot,
}

var select_box_positions: Dictionary = {
	Options.FIRST_SLOT: Vector2(25, 6),      # Adjust these coordinates to match your layout
	Options.SECOND_SLOT: Vector2(137, 6),
	Options.THIRD_SLOT: Vector2(25, 49),
	Options.FOURTH_SLOT: Vector2(137, 49),
	Options.FIFTH_SLOT: Vector2(25, 92),
	Options.SIXTH_SLOT: Vector2(137, 92),
}

var slots_enabled: Dictionary = {
	Options.FIRST_SLOT: true,
	Options.SECOND_SLOT: true,
	Options.THIRD_SLOT: true,
	Options.FOURTH_SLOT: true,
	Options.FIFTH_SLOT: true,
	Options.SIXTH_SLOT: true,
}

var pause = true


func _ready() -> void:
	visible = false
	pause = true


func load_screen():
	visible = true
	pause = false
	selected_option = Options.FIRST_SLOT
	load_party()
	update_select_box()
	var choice = await choose_grammarite()
	pause = true
	return choice


func choose_grammarite():
	while visible:
		await get_tree().process_frame
	
	return selected_option



func update_select_box():
	$SelectBox.visible = true
	$SelectBox.position = select_box_positions[selected_option]

func load_party():
	var party = Utils.get_party()
	for i in range(6):
		var slot = options[i]
		var slot_data = party[i]
		if slot_data["Name"] == "":
			slot.visible = false
			slots_enabled[i] = false
			$Covers.get_child(i).visible = true
		else:
			slot.lvl.text = str(int(slot_data["Level"]))
			var max_hp = Utils.max_hp(slot_data["Name"], slot_data["Level"])
			if slot_data["Item"] == "Colon":
				max_hp *= 1.1
				max_hp += 10
			slot.set_health(max_hp, slot_data["Health"])
			slot.set_sprites(Utils.get_poke_num(slot_data["Name"]))
			slots_enabled[i] = true
			$Covers.get_child(i).visible = false


func _input(event):
	if pause: return
	if event.is_action_pressed("ui_down"):
		# Move down two slots (to next row)
		var next_option = selected_option + 2
		if next_option <= Options.SIXTH_SLOT:
			selected_option = next_option
			# Skip if not enabled
			while not slots_enabled[selected_option] and selected_option <= Options.SIXTH_SLOT:
				selected_option += 2
				if selected_option > Options.SIXTH_SLOT:
					selected_option = (selected_option - 1)%len(Options)
		update_select_box()
	
	elif event.is_action_pressed("ui_up"):
		if selected_option > Options.SECOND_SLOT:
			# Move up two slots (to previous row)
			selected_option -= 2
			update_select_box()
	
	elif event.is_action_pressed("ui_left"):
		if selected_option % 2 == 1:  # Right column (odd indices: 1, 3, 5)
			# Move to left column
			selected_option -= 1
			update_select_box()
		# If already in left column (even indices: 0, 2, 4), do nothing
	
	elif event.is_action_pressed("ui_right"):
		if selected_option % 2 == 0:  # Left column (even indices: 0, 2, 4)
			# Move to right column
			selected_option += 1
			# Skip if not enabled
			while not slots_enabled[selected_option] and selected_option >= Options.FIRST_SLOT:
				selected_option -= 2
				if selected_option < Options.FIRST_SLOT:
					selected_option = (selected_option + 1)%num_of_slots   # Go back
			update_select_box()
		# If already in right column (odd indices: 1, 3, 5), do nothing
	
	elif event.is_action_pressed("z"):
		visible = false
