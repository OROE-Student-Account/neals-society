extends Node2D

var items : Array

enum State { ITEM_LIST, GRAMMARITE_SELECT }
var current_state = State.ITEM_LIST

var selected_grammarite: int = 0

@onready var grammarite_slots: Array[Sprite2D] = [
	$Slots/FirstPokemonSlot/Background,
	$Slots/SecondPokemonSlot/Background,
	$Slots/ThirdPokemonSlot/Background,
	$Slots/FourthPokemonSlot/Background,
	$Slots/FifthPokemonSlot/Background,
	$Slots/SixthPokemonSlot/Background,
]

var slots_enabled: Dictionary = {
	0: true,
	1: true,
	2: true,
	3: true,
	4: true,
	5: true,
}

func _ready() -> void:
	$ItemList.grab_focus()
	
	# Load items
	var inv = Utils.get_items()
	items.append({"Name": inv[0], "Count": 0})
	for i in inv:
		var found = false
		for j in items:
			if j["Name"] == i:
				j["Count"] += 1
				found = true
				break
		if not found:
			items.append({"Name": i, "Count": 1})
	
	for i in items:
		$ItemList.add_item(i["Name"] + " " + str(i["Count"]) + "x")
	
	_on_item_list_item_selected(0)
	
	# Load party into slots
	load_party()
	
	# Hide grammarite selection initially
	hide_grammarite_selection()

func load_party():
	var party = Utils.get_party()
	for i in range(6):
		var slot = grammarite_slots[i].get_parent()
		var slot_data = party[i]
		if slot_data["Name"] == "":
			slot.visible = false
			slots_enabled[i] = false
		else:
			var max_health = Utils.get_grammarite_details(slot_data["Name"])["Stats"]["Health"]
			slot.lvl.text = str(int(slot_data["Level"]))
			slot.set_health(max_health, slot_data["Health"])
			slot.set_sprites(Utils.get_poke_num(slot_data["Name"]))
			slots_enabled[i] = true

func show_grammarite_selection():
	$Slots.visible = true
	
	# Select first available slot
	selected_grammarite = 0
	while not slots_enabled[selected_grammarite]:
		selected_grammarite = (selected_grammarite + 1) % 6
	
	set_active_grammarite()
	
	# Visual feedback
	$Info/Description.text = "Select a Grammarite to use this item on."
	
	$ItemList.focus_mode = Control.FOCUS_NONE
	$ItemList.release_focus()

func hide_grammarite_selection():
	# Hide grammarite selection indicators
	$Slots.visible = false
	for i in range(6):
		grammarite_slots[i].frame = 0
	
	$ItemList.focus_mode = Control.FOCUS_ALL
	$ItemList.grab_focus()

func set_active_grammarite():
	# Unset all first
	for i in range(6):
		grammarite_slots[i].frame = 0
	# Set selected
	grammarite_slots[selected_grammarite].frame = 1

func _on_item_list_item_selected(index: int) -> void:
	var item = Utils.get_item(items[index]["Name"])
	
	$Info/Description.text = item["Description"]
	var file_path = "res://Assets/Items/" + items[index]["Name"] + ".png"
	$Info/ItemSprite.texture = load(file_path)
	
	# Don't show grammarite selection when just browsing
	if current_state == State.ITEM_LIST:
		hide_grammarite_selection()

func show_based_on_type(type):
	match type:
		"Book":
			pass
		"Grammarite":
			pass
		"Held":
			pass
		"Consumable":
			pass
		"Passive":
			pass

func use_item_on_grammarite():
	var selected_item_index = $ItemList.get_selected_items()[0]
	var item = Utils.get_item(items[selected_item_index]["Name"])
	
	# TODO: Apply item effect to the grammarite
	# For example:
	# var party = Utils.get_party()
	# party[selected_grammarite]["Health"] += 20  # If it's a potion
	# Utils.set_party(party)
	
	# Decrease item count
	items[selected_item_index]["Count"] -= 1
	
	if items[selected_item_index]["Count"] <= 0:
		items.remove_at(selected_item_index)
		$ItemList.remove_item(selected_item_index)
		if $ItemList.item_count > 0:
			$ItemList.select(min(selected_item_index, $ItemList.item_count - 1))
			_on_item_list_item_selected($ItemList.get_selected_items()[0])
	else:
		# Update display
		$ItemList.set_item_text(selected_item_index, 
			items[selected_item_index]["Name"] + " " + str(items[selected_item_index]["Count"]) + "x")
	
	# Go back to item list
	current_state = State.ITEM_LIST
	hide_grammarite_selection()
	$ItemList.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	match current_state:
		State.ITEM_LIST:
			if event.is_action_pressed("ui_left"):
				# Check if current item is Grammarite type
				var selected_indices = $ItemList.get_selected_items()
				if selected_indices.size() > 0:
					var item = Utils.get_item(items[selected_indices[0]]["Name"])
					if item["Type"] == "Grammarite":
						current_state = State.GRAMMARITE_SELECT
						show_grammarite_selection()
			
			elif event.is_action_pressed("x"):
				# Exit back to menu/game
				Utils.get_scene_manager().transition_exit_party_screen()  # Or whatever your exit function is
		
		State.GRAMMARITE_SELECT:
			if event.is_action_pressed("ui_right"):
				# Go back to item list
				current_state = State.ITEM_LIST
				hide_grammarite_selection()
				$ItemList.grab_focus()
				# Restore description
				var selected_indices = $ItemList.get_selected_items()
				if selected_indices.size() > 0:
					_on_item_list_item_selected(selected_indices[0])
			
			elif event.is_action_pressed("ui_down"):
				set_active_grammarite()
				grammarite_slots[selected_grammarite].frame = 0
				selected_grammarite = (selected_grammarite + 1) % 6
				while not slots_enabled[selected_grammarite]:
					selected_grammarite = (selected_grammarite + 1) % 6
				set_active_grammarite()
			
			elif event.is_action_pressed("ui_up"):
				grammarite_slots[selected_grammarite].frame = 0
				selected_grammarite = (selected_grammarite + 5) % 6
				while not slots_enabled[selected_grammarite]:
					selected_grammarite = (selected_grammarite + 5) % 6
				set_active_grammarite()
			
			elif event.is_action_pressed("z"):
				# Use item on selected grammarite
				use_item_on_grammarite()
			
			elif event.is_action_pressed("x"):
				# Cancel grammarite selection
				current_state = State.ITEM_LIST
				hide_grammarite_selection()
				$ItemList.grab_focus()
				var selected_indices = $ItemList.get_selected_items()
				if selected_indices.size() > 0:
					_on_item_list_item_selected(selected_indices[0])
