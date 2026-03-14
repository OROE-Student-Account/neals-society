extends Node2D

var pause = false

var items : Array
var filtered_items : Array  # Items after filtering by type

enum State { ITEM_TYPE_SELECT, ITEM_LIST, GRAMMARITE_SELECT }
var current_state = State.ITEM_TYPE_SELECT

var selected_grammarite: int = 0
var selected_item_type: int = 0  # Which type filter is selected

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

@onready var item_type_buttons: Array[Sprite2D] = [
	$ItemTypes/Book,
	$ItemTypes/Grammarite
]

@onready var item_type_names: Array[String] = [
	"Book",
	"Grammarite"
]

func _ready() -> void:
	load_inventory()
	load_party()
	
	# Start with item type selection
	current_state = State.ITEM_TYPE_SELECT
	set_active_item_type()
	filter_items_by_type()
	
	hide_grammarite_selection()

func stop():
	pause = true
	await get_tree().create_timer(0.1).timeout
	pause = false

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

func set_active_grammarite():
	# Unset all first
	for i in range(6):
		grammarite_slots[i].frame = 0
	# Set selected
	grammarite_slots[selected_grammarite].frame = 1

func set_active_item_type():
	# Unset all item type buttons
	for i in range(len(item_type_buttons)):
		item_type_buttons[i].frame = 1  # 1 = unselected
	# Set selected
	item_type_buttons[selected_item_type].frame = 0  # 0 = selected

func filter_items_by_type():
	# Filter items array by the selected type
	var selected_type = item_type_names[selected_item_type]
	
	filtered_items.clear()
	for item_data in items:
		var item_details = Utils.get_item(item_data["Name"])
		if item_details["Type"] == selected_type:
			filtered_items.append(item_data)
	
	# Rebuild the ItemList
	$ItemList.clear()
	for i in filtered_items:
		$ItemList.add_item(i["Name"] + " " + str(i["Count"]) + "x")
	
	# Select first item if any exist
	if $ItemList.item_count > 0:
		$ItemList.select(0)
		_on_item_list_item_selected(0)
	else:
		# No items of this type
		$Info/Description.text = "No items of this type."
		$Info/ItemSprite.texture = null

func _on_item_list_item_selected(index: int) -> void:
	if index >= len(filtered_items):
		return
	
	var item = Utils.get_item(filtered_items[index]["Name"])
	
	$Info/Description.text = item["Description"]
	var file_path = "res://Assets/Items/" + filtered_items[index]["Name"] + ".png"
	$Info/ItemSprite.texture = load(file_path)
	
	# Don't show grammarite selection when just browsing
	if current_state == State.ITEM_LIST:
		hide_grammarite_selection()

func show_based_on_type(type):
	match type:
		"Book":
			pass
		"Grammarite":
			current_state = State.GRAMMARITE_SELECT
			show_grammarite_selection()
			stop()

func load_inventory():
	# Load items
	var inv = Utils.get_items()
	
	items.clear()
	filtered_items.clear()
	$ItemList.clear()
	
	if len(inv) > 0:
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

func use_item_on_grammarite():
	var selected_item_index = $ItemList.get_selected_items()[0]
	var item = Utils.get_item(filtered_items[selected_item_index]["Name"])
	
	if item["Type"] == "Held":
		var party = Utils.get_party()
		var temp = party[selected_grammarite]["Item"]
		party[selected_grammarite]["Item"] = filtered_items[selected_item_index]["Name"]
		
		if temp != "":
			Utils.add_to_inventory(temp)
	
	# TODO: Apply item effect to the grammarite
	
	# Decrease item count
	if not Utils.remove_from_inventory(filtered_items[selected_item_index]["Name"]):
		print("Never was there?")
	
	load_inventory()
	filter_items_by_type()  # Refilter after inventory change
	
	# Go back to item list
	current_state = State.ITEM_LIST
	hide_grammarite_selection()
	$ItemList.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if pause: return
	
	match current_state:
		State.ITEM_TYPE_SELECT:
			if event.is_action_pressed("ui_right"):
				selected_item_type = (selected_item_type + 1) % len(item_type_buttons)
				set_active_item_type()
				filter_items_by_type()
			
			elif event.is_action_pressed("ui_left"):
				selected_item_type = (selected_item_type + len(item_type_buttons) - 1) % len(item_type_buttons)
				set_active_item_type()
				filter_items_by_type()
			
			elif event.is_action_pressed("ui_down") or event.is_action_pressed("z"):
				# Go to item list
				if $ItemList.item_count > 0:
					current_state = State.ITEM_LIST
					$ItemList.grab_focus()
			
			elif event.is_action_pressed("x"):
				# Exit
				var UI = get_parent().get_node("BattleUI")
				UI.stop()
				UI.input_state = 0
				UI.show_correct_menu()
				get_parent().get_node("Grammarite").setup()
				queue_free()
		
		State.ITEM_LIST:
			if event.is_action_pressed("ui_up"):
				# Check if we're at the top of the list
				var selected_indices = $ItemList.get_selected_items()
				if selected_indices.size() > 0 and selected_indices[0] == 0:
					# Go back to type selection
					current_state = State.ITEM_TYPE_SELECT
					$ItemList.release_focus()
			
			elif event.is_action_pressed("z"):
				# Check if current item is Grammarite type
				var selected_indices = $ItemList.get_selected_items()
				if selected_indices.size() > 0:
					var item = Utils.get_item(filtered_items[selected_indices[0]]["Name"])
					show_based_on_type(item["Type"])
			
			elif event.is_action_pressed("x"):
				# Go back to type selection
				current_state = State.ITEM_TYPE_SELECT
				$ItemList.release_focus()
		
		State.GRAMMARITE_SELECT:
			if event.is_action_pressed("x"):
				# Go back to item list
				current_state = State.ITEM_LIST
				hide_grammarite_selection()
				$ItemList.grab_focus()
				# Restore description
				var selected_indices = $ItemList.get_selected_items()
				if selected_indices.size() > 0:
					_on_item_list_item_selected(selected_indices[0])
			
			elif event.is_action_pressed("ui_down"):
				if selected_grammarite < 4:
					grammarite_slots[selected_grammarite].frame = 0
					selected_grammarite = (selected_grammarite + 2) % 6
					while not slots_enabled[selected_grammarite]:
						selected_grammarite = (selected_grammarite + 2) % 6
					set_active_grammarite()
			
			elif event.is_action_pressed("ui_up"):
				if selected_grammarite > 1:
					grammarite_slots[selected_grammarite].frame = 0
					selected_grammarite = (selected_grammarite + 4) % 6
					while not slots_enabled[selected_grammarite]:
						selected_grammarite = (selected_grammarite + 4) % 6
					set_active_grammarite()
			
			elif event.is_action_pressed("ui_right"):
				if selected_grammarite % 2 == 0:
					grammarite_slots[selected_grammarite].frame = 0
					selected_grammarite = (selected_grammarite + 1) % 6
					while not slots_enabled[selected_grammarite]:
						selected_grammarite = (selected_grammarite + 1) % 6
					set_active_grammarite()
			
			elif event.is_action_pressed("ui_left"):
				if selected_grammarite % 2 != 0:
					grammarite_slots[selected_grammarite].frame = 0
					selected_grammarite = (selected_grammarite + 5) % 6
					while not slots_enabled[selected_grammarite]:
						selected_grammarite = (selected_grammarite + 5) % 6
					set_active_grammarite()
			
			elif event.is_action_pressed("z"):
				# Use item on selected grammarite
				use_item_on_grammarite()
