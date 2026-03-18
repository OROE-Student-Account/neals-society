extends Node2D

var pause = false

var items : Array
var filtered_items : Array  # Items after filtering by type

enum State { ITEM_TYPE_SELECT, ITEM_LIST }
var current_state = State.ITEM_TYPE_SELECT

var selected_item_type: int = 0  # Which type filter is selected


var in_battle = false


@onready var item_type_buttons: Array[Sprite2D] = [
	$ItemTypes/Book,
	$ItemTypes/Held,
	$ItemTypes/Grammarite,
	$ItemTypes/Consumable,
	$ItemTypes/Passive
]

@onready var item_type_names: Array[String] = [
	"Book",
	"Held",
	"Grammarite",
	"Consumable",
	"Passive"
]

func _ready() -> void:
	load_inventory()
	
	# Start with item type selection
	current_state = State.ITEM_TYPE_SELECT
	set_active_item_type()
	filter_items_by_type()
	
	if in_battle:
		$ItemTypes/Held.visible = false
		$ItemTypes/Consumable.visible = false
		$ItemTypes/Passive.visible = false
		item_type_buttons.remove_at(4)
		item_type_buttons.remove_at(3)
		item_type_buttons.remove_at(1)
		item_type_names.remove_at(4)
		item_type_names.remove_at(3)
		item_type_names.remove_at(1)


func stop():
	pause = true
	await get_tree().create_timer(0.1).timeout
	pause = false


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
		var item_details = Utils.get_item_data(item_data["Name"])
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
	
	var item = Utils.get_item_data(filtered_items[index]["Name"])
	
	$Info/Description.text = item["Description"]
	var file_path = "res://Assets/Items/" + filtered_items[index]["Name"] + ".png"
	$Info/ItemSprite.texture = load(file_path)


func show_based_on_type(type):
	match type:
		"Book":
			if in_battle:
				var selected_item_index = $ItemList.get_selected_items()[0]
				var battle_manager = get_parent().get_node("BattleManager")
				battle_manager.throw_book(filtered_items[selected_item_index]["Name"])
				
				var file_path = "res://Assets/Items/" + filtered_items[selected_item_index]["Name"] + ".png"
				get_parent().get_node("BookAnimation/Book").texture = load(file_path)
				
				if not Utils.remove_from_inventory(filtered_items[selected_item_index]["Name"]):
					print("Never was there?")
				exit(true)
		"Held":
			use_item_on_grammarite()
		"Grammarite":
			use_item_on_grammarite()
		"Consumable":
			pass
		"Passive":
			pass

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
	
	$ItemList.focus_mode = Control.FOCUS_NONE
	$ItemList.release_focus()
	
	pause = true
	
	var index = await Utils.get_scene_manager().transition_to_select_screen()
	
	var selected_item_index = $ItemList.get_selected_items()[0]
	var item = Utils.get_item_data(filtered_items[selected_item_index]["Name"])
	var party = Utils.get_party()
	
	if item["Type"] == "Held":
		var temp = party[index]["Item"]
		party[index]["Item"] = filtered_items[selected_item_index]["Name"]
		
		if temp != "":
			Utils.add_to_inventory(temp)
	
	elif item["Type"] == "Grammarite":
		
		if filtered_items[selected_item_index]["Name"] == "Potion":
			var max_hp = Utils.max_hp(party[index]["Name"], party[index]["Level"])
			party[index]["Health"] = int(min(party[index]["Health"]+(max_hp/2), max_hp))
			
	
	# TODO: Apply item effect to the grammarite
	
	# Decrease item count
	if not Utils.remove_from_inventory(filtered_items[selected_item_index]["Name"]):
		print("Never was there?")
	
	Utils.set_party(party)
	
	load_inventory()
	filter_items_by_type()  # Refilter after inventory change
	
	# Go back to item list
	current_state = State.ITEM_LIST
	
	pause = false

	$ItemList.focus_mode = Control.FOCUS_ALL
	$ItemList.grab_focus()


# battle func
func exit(thrown):
	var UI = get_parent().get_node("BattleUI")
	UI.stop()
	if !thrown:
		UI.input_state = 0
		UI.show_correct_menu()
	get_parent().get_node("Grammarite").setup()
	queue_free()

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
				if not in_battle:
					Utils.get_scene_manager().transition_exit_item_screen()
				else:
					exit(false)
		
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
					var item = Utils.get_item_data(filtered_items[selected_indices[0]]["Name"])
					show_based_on_type(item["Type"])
			
			elif event.is_action_pressed("x"):
				# Go back to type selection
				current_state = State.ITEM_TYPE_SELECT
				$ItemList.release_focus()
