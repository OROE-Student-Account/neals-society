extends Node2D

var pause = false

var items : Array
var filtered_items : Array  # Items after filtering by type

enum State { ITEM_TYPE_SELECT, ITEM_SELECTION }
var current_state = State.ITEM_TYPE_SELECT

var selected_item_type: int = 0  # Which type filter is selected
var selected_item_index: int = 0  # Which item is selected in the grid

var in_battle = false

# Grid positions for items (2 columns x 6 rows)
var item_positions: Array[Vector2] = [
	Vector2(129, 27),    # 0
	Vector2(154, 27),    # 1
	Vector2(180, 27),    # 2
	Vector2(205, 27),    # 3
	Vector2(129, 52),    # row 2
	Vector2(154, 52),    # 5
	Vector2(180, 52),   # 6
	Vector2(205, 52),   # 7
	Vector2(129, 77),   # row 3
	Vector2(154, 77),   # 9
	Vector2(180, 77),   # 10
	Vector2(205, 77),   # 11
]

var item_sprites: Array[Sprite2D] = []  # Stores the created item sprites
@onready var select_box = $SelectBox

@onready var item_type_names: Array[String] = [
	"Grammarite",
	"Book",
	"Consumable",
	"Held",
	"Passive",
	"Shard"
]

func _ready() -> void:
	load_inventory()
	
	# Create select box
	select_box.visible = false
	
	# Start with item type selection
	current_state = State.ITEM_TYPE_SELECT
	set_active_item_type()
	filter_items_by_type()
	
	$BattleBlockers.visible = false
	if in_battle:
		$BattleBlockers.visible = true
		item_type_names.remove_at(5)
		item_type_names.remove_at(4)
		item_type_names.remove_at(3)

func stop():
	pause = true
	await get_tree().create_timer(0.1).timeout
	pause = false

func load_inventory():
	# Load items
	var inv = Utils.get_items()
	
	items.clear()
	filtered_items.clear()
	
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
	
	$Money/Label.text = "$: "+str(Utils.get_money())

func set_active_item_type():
	$Type.position.y = 15 * selected_item_type

func clear_item_sprites():
	# Remove all existing item sprites
	for sprite in item_sprites:
		sprite.queue_free()
	item_sprites.clear()

func filter_items_by_type():
	# Filter items array by the selected type
	var selected_type = item_type_names[selected_item_type]
	
	filtered_items.clear()
	for item_data in items:
		var item_details = Utils.get_item_data(item_data["Name"])
		if item_details["Type"] == selected_type:
			filtered_items.append(item_data)
	
	# Clear old sprites
	clear_item_sprites()
	
	# Create sprites for each filtered item (up to 12)
	for i in range(min(filtered_items.size(), 12)):
		var item_sprite = Sprite2D.new()
		var file_path = "res://Assets/Items/" + filtered_items[i]["Name"] + ".png"
		item_sprite.scale = Vector2(0.5, 0.5)
		item_sprite.texture = load(file_path)
		item_sprite.position = item_positions[i]
		add_child(item_sprite)
		item_sprites.append(item_sprite)
	
	# Reset selection
	selected_item_index = 0
	
	# Update info display
	if filtered_items.size() > 0:
		update_item_info()
	else:
		# No items of this type
		$Info/Description.text = "No items of this type."
		$Info/ItemSprite.texture = null
		$Info/Count.text = ""
		$Info/Name.text = ""

func update_item_info():
	if selected_item_index >= len(filtered_items):
		return
	
	var item = Utils.get_item_data(filtered_items[selected_item_index]["Name"])
	
	$Info/Count.text = str(filtered_items[selected_item_index]["Count"]) + "x"
	$Info/Name.text = filtered_items[selected_item_index]["Name"]
	$Info/Description.text = item["Description"]
	var file_path = "res://Assets/Items/" + filtered_items[selected_item_index]["Name"] + ".png"
	$Info/ItemSprite.texture = load(file_path)
	
	# Update select box position
	select_box.position = item_positions[selected_item_index]

func show_based_on_type(type):
	match type:
		"Book":
			if in_battle:
				var battle_manager = get_parent().get_node("BattleManager")
				
				if battle_manager.trainer != "random": return
				
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

func use_item_on_grammarite():
	pause = true
	select_box.visible = false
	
	
	var item_name = filtered_items[selected_item_index]["Name"]
	var item = Utils.get_item_data(item_name)
	var party = Utils.get_party()
	
	var index = 0
	if item_name != "Semicolon":
		index = await Utils.get_scene_manager().transition_to_select_screen()
	
	if item["Type"] == "Held":
		var temp = party[index]["Item"]
		party[index]["Item"] = item_name
		
		if temp != "":
			Utils.add_to_inventory(temp)
	
	elif item["Type"] == "Grammarite":
		if item_name == "Semicolon":
			if in_battle:
				var battle_manager = get_parent().get_node("BattleManager")
				battle_manager._on_player_move_selected(-3)
		elif item_name == "Potion":
			var max_hp = Utils.max_hp(party[index]["Name"], party[index]["Level"])
			party[index]["Health"] = int(min(party[index]["Health"] + (max_hp / 2), max_hp))
	
	# Decrease item count
	if not Utils.remove_from_inventory(item_name):
		print("Never was there?")
	
	Utils.set_party(party)
	
	load_inventory()
	filter_items_by_type()
	
	# Go back to item selection
	current_state = State.ITEM_SELECTION
	select_box.visible = true
	
	pause = false

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
			if event.is_action_pressed("ui_down"):
				selected_item_type = (selected_item_type + 1) % len(item_type_names)
				set_active_item_type()
				filter_items_by_type()
			
			elif event.is_action_pressed("ui_up"):
				selected_item_type = (selected_item_type + len(item_type_names) - 1) % len(item_type_names)
				set_active_item_type()
				filter_items_by_type()
			
			elif event.is_action_pressed("ui_right") or event.is_action_pressed("z"):
				# Go to item selection
				if filtered_items.size() > 0:
					current_state = State.ITEM_SELECTION
					select_box.visible = true
					update_item_info()
			
			elif event.is_action_pressed("x"):
				# Exit
				if not in_battle:
					Utils.get_scene_manager().transition_exit_menu("Item")
				else:
					exit(false)
		
		State.ITEM_SELECTION:
			if event.is_action_pressed("ui_down"):
				# Move down 4 positions (next row)
				var next_index = selected_item_index + 4
				if next_index < filtered_items.size():
					selected_item_index = next_index
					update_item_info()
			
			elif event.is_action_pressed("ui_up"):
				# Move up 4 positions (previous row)
				var prev_index = selected_item_index - 4
				if prev_index >= 0:
					selected_item_index = prev_index
					update_item_info()
			
			elif event.is_action_pressed("ui_left"):
				# Move left if not in leftmost column
				if selected_item_index % 4 != 0:  # Not in column 0
					selected_item_index -= 1
					update_item_info()
				else:
					# If at leftmost, go back to type selection
					current_state = State.ITEM_TYPE_SELECT
					select_box.visible = false
			
			elif event.is_action_pressed("ui_right"):
				# Move right if not in rightmost column and item exists
				if selected_item_index % 4 != 3 and selected_item_index + 1 < filtered_items.size():
					selected_item_index += 1
					update_item_info()
			
			elif event.is_action_pressed("z"):
				# Use the selected item
				var item = Utils.get_item_data(filtered_items[selected_item_index]["Name"])
				show_based_on_type(item["Type"])
			
			elif event.is_action_pressed("x"):
				# Go back to type selection
				current_state = State.ITEM_TYPE_SELECT
				select_box.visible = false
