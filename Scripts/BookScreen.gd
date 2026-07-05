extends Node2D

var selected_slot: int = 0
@onready var selecter = $selecter

# Grid configuration (5 rows x 5 columns = 25 slots)
var slot_positions: Array[Vector2] = []
var bookshelf = []
var active: bool = false

func _ready():
	# Dynamically generate 5x5 grid positions
	for row in range(5):
		for col in range(5):
			var x = 5 + col * 49
			var y = 1 + row * 26
			slot_positions.append(Vector2(x, y))
			
	load_bookshelf()

func load_bookshelf():
	active = true
	selected_slot = 0
	
	clear_slots()
	
	var shelf = Utils.get_bookshelf()  
	
	# Clean up shelf data: replace any grammarites missing a name with {}
	for i in range(shelf.size()):
		if shelf[i] == null or shelf[i] == {} or not shelf[i].has("Name") or shelf[i]["Name"] == "":
			shelf[i] = {}
	Utils.set_bookshelf(shelf) # Save cleaned array back to global state
	
	# Loop through all 25 grid slots
	for i in range(25):
		var slot_pos = slot_positions[i]
		
		# Check if valid data exists for this slot
		if i < shelf.size() and shelf[i] != {}:
			var grammarite_num = Utils.get_poke_num(shelf[i]["Name"]) + 1
			
			var sprite = Sprite2D.new()
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0, 34, 64, 64)
			sprite.centered = false
			sprite.scale = Vector2(0.5, 0.5)
			sprite.flip_h = true
			sprite.texture = load("res://Assets/Pokemon/Pokemon" + str(grammarite_num) + ".png")
			
			sprite.position = slot_pos
			add_child(sprite)
			
			bookshelf.append(shelf[i])
		else:
			bookshelf.append({})
	
	selecter.visible = true
	update_selecter_position()

func clear_slots():
	# Clean up runtime sprites
	for child in get_children():
		if child == selecter:
			continue
		if child is Sprite2D:
			child.queue_free()
	
	bookshelf.clear()

func update_selecter_position():
	selecter.position = slot_positions[selected_slot]

func confirm_selection():
	active = false
	
	var party = Utils.get_party()
	
	# Count how many valid grammarites are currently in the party
	var valid_party_count = 0
	for member in party:
		if member != {} and member.has("Name") and member["Name"] != "":
			valid_party_count += 1
	
	if bookshelf[selected_slot] == {}:
		# Player is trying to DEPOSIT a party member into an empty slot
		if valid_party_count <= 1:
			# Block the action if it's their last remaining grammarite
			print("Cannot deposit your last Grammarite!") 
			active = true
			return
			
		var index = await Utils.get_scene_manager().transition_to_select_screen()
		
		# Handle selection cancellation or invalid selection
		if index == -1 or party[index] == {} or party[index]["Name"] == "":
			active = true
			return
			
		bookshelf[selected_slot] = party[index]
		
		for i in range(index, 5):
			party[i] = party[i+1]
		party[5] = {
			"Health": 0.0,
			"Item": "",
			"Level": 1.0,
			"Moves": [],
			"Name": "",
			"Nickname": "",
			"PP": []
		}
	else:
		# Player is SWAPPING or WITHDRAWING from a filled slot
		var empty_party_slots = 0
		for i in range(6):
			if party[i]["Name"] == "":
				empty_party_slots += 1
		
		if empty_party_slots == 0:
			# Party full: Must swap with an existing member
			var index = await Utils.get_scene_manager().transition_to_select_screen()
			if index == -1:
				active = true
				return
				
			var temp_item = party[index]
			party[index] = bookshelf[selected_slot]
			bookshelf[selected_slot] = temp_item
		else:
			# Party has space: Direct withdrawal
			for i in range(6):
				if party[i]["Name"] == "":
					party[i] = bookshelf[selected_slot]
					bookshelf[selected_slot] = {}
					break
		
	Utils.set_party(party)
	Utils.set_bookshelf(bookshelf)
	
	load_bookshelf()
	
	active = true

func _input(event: InputEvent) -> void:
	if not active:
		return
	
	if event.is_action_pressed("ui_down"):
		var next_slot = selected_slot + 5
		if next_slot < 25:
			selected_slot = next_slot
			update_selecter_position()
	
	elif event.is_action_pressed("ui_up"):
		var prev_slot = selected_slot - 5
		if prev_slot >= 0:
			selected_slot = prev_slot
			update_selecter_position()
	
	elif event.is_action_pressed("ui_left"):
		if selected_slot % 5 != 0:
			selected_slot -= 1
			update_selecter_position()
	
	elif event.is_action_pressed("ui_right"):
		if selected_slot % 5 != 4 and selected_slot + 1 < 25:
			selected_slot += 1
			update_selecter_position()
	
	elif event.is_action_pressed("z"):
		confirm_selection()
	
	elif event.is_action_pressed("x"):
		Utils.get_scene_manager().transition_exit_menu("Bookshelf")
