extends Node2D

var selected_slot: int = 0
@onready var selecter = $temp/selecter

# Grid positions for the selecter (3 rows x 4 columns)
const slot_positions: Array[Vector2] = [
	Vector2(12, 5),    # 0
	Vector2(80, 5),    # 1
	Vector2(150, 5),   # 2
	Vector2(220, 5),   # 3
	Vector2(12, 60),    # 4
	Vector2(80, 60),    # 5
	Vector2(150, 60),   # 6
	Vector2(220, 60),   # 7
	Vector2(12, 100),   # 8
	Vector2(80, 100),   # 9
	Vector2(150, 100),  # 10
	Vector2(220, 100),  # 11
]

var bookshelf = []


var active: bool = false

func _ready():
	load_bookshelf()

func load_bookshelf():
	active = true
	selected_slot = 0
	
	clear_slots()
	
	var slots = $temp.get_children()
	var shelf = Utils.get_bookshelf()  
	
	for i in range(2,14):
		
		var g_name = Label.new()
		g_name.theme = load("res://Assets/UI/Fonts.tres")
		
		
		# Set grammarite sprite and name based on  bookshelf
		var j = i - 2
		if j < shelf.size():
			if shelf[j] == {}:
				g_name.text = "Empty"
				bookshelf.append({})
			else:
				var grammarite_num = Utils.get_poke_num(shelf[j]["Name"]) + 1
				# Set texture based on grammarite number
				
				var sprite = Sprite2D.new()
				sprite.region_enabled = true
				sprite.region_rect = Rect2(0, 34, 64, 64)
				sprite.centered = false
				sprite.scale = Vector2(0.5, 0.5)
				sprite.flip_h = true
				sprite.texture = load("res://Assets/Pokemon/Pokemon" + str(grammarite_num) + ".png")
				slots[i].add_child(sprite)
				
				g_name.text = shelf[j]["Name"]
				
				bookshelf.append(shelf[j])
		
		
		
		slots[i].add_child(g_name)
	
	selecter.visible = true
	update_selecter_position()

func clear_slots():
	# Remove all existing sprites from slots
	var slots = $temp.get_children()
	for slot in slots:
		for child in slot.get_children():
			if child is Sprite2D or child is Label:
				child.queue_free()
	
	bookshelf.clear()

func update_selecter_position():
	selecter.position = slot_positions[selected_slot]

func confirm_selection():
	active = false
	
	var party = Utils.get_party()
	
	if bookshelf[selected_slot] == {}:
		var index = await Utils.get_scene_manager().transition_to_select_screen()
		
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
		var count = 0
		for i in range(6):
			if party[i]["Name"] == "":
				count += 1
		
		if count == 0:
			var index = await Utils.get_scene_manager().transition_to_select_screen()
			
			var temp = party[index]
			party[index] = bookshelf[selected_slot]
			bookshelf[selected_slot] = temp
		else:
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
		# Move down 4 positions (next row)
		var next_slot = selected_slot + 4
		if next_slot < 12:
			selected_slot = next_slot
			update_selecter_position()
	
	elif event.is_action_pressed("ui_up"):
		# Move up 4 positions (previous row)
		var prev_slot = selected_slot - 4
		if prev_slot >= 0:
			selected_slot = prev_slot
			update_selecter_position()
	
	elif event.is_action_pressed("ui_left"):
		# Move left if not in leftmost column
		if selected_slot % 4 != 0:
			selected_slot -= 1
			update_selecter_position()
	
	elif event.is_action_pressed("ui_right"):
		# Move right if not in rightmost column and slot exists
		if selected_slot % 4 != 3 and selected_slot + 1 < 12:
			selected_slot += 1
			update_selecter_position()
	
	elif event.is_action_pressed("z"):
		confirm_selection()
	
	elif event.is_action_pressed("x"):
		# exit
		Utils.get_scene_manager().transition_exit_bookshelf()
