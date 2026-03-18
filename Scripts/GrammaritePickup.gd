extends Node2D



@export var grammarite_name: String = ""
@onready var grammarite_sprite = load("res://Assets/Pokemon/Pokemon"+str(Utils.get_poke_num(grammarite_name)+1)+".png")

var picked_up = false
var in_menu = false
var used_up = false

@onready var menu_scene = preload("res://Scenes/GrammaritePickupMenu.tscn")

var selected_button = 0

func open_menu():
	var player = Utils.get_player()
	player.set_physics_process(false)
	in_menu = true
	
	var menu = menu_scene.instantiate()
	menu.get_node("Grammarite").texture = grammarite_sprite
	Utils.get_scene_manager().add_child(menu)
	
	selected_button = 0
	update_buttons()


func close_menu():
	Utils.get_scene_manager().get_children().back().queue_free()
	Utils.get_player().set_physics_process(true)
	in_menu = false
	reset()


func update_buttons():
	var menu = Utils.get_scene_manager().get_children().back()
	if selected_button == 0:
		menu.get_node("Take").frame = 1
		menu.get_node("Leave").frame = 0
	else:
		menu.get_node("Take").frame = 0
		menu.get_node("Leave").frame = 1


func _unhandled_input(event: InputEvent) -> void:
	var player = Utils.get_player()
	if player.can_interact_with_object and event.is_action_pressed("z") and picked_up and !in_menu and !used_up:
		
		var player_facing = player.facing_direction
		var player_pos = player.position
		if player_facing != 0 && player_pos.x > position.x && player_pos.y == position.y:
			return
		if player_facing != 1 && player_pos.x < position.x && player_pos.y == position.y:
			return
		if player_facing != 2 && player_pos.x == position.x && player_pos.y > position.y:
			return
		if player_facing != 3  && player_pos.x == position.x && player_pos.y < position.y:
			return
		
		used_up = true
		
		open_menu()
	elif in_menu:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			selected_button = 1 - selected_button
			update_buttons()
		if event.is_action_pressed("x") or (selected_button == 1 and event.is_action_pressed("z")):
			close_menu()
		elif event.is_action_pressed("z"):
			var party = Utils.get_party()
			var empty_slot = -1
			for i in range(6):
				if party[i]["Name"] == "":
					empty_slot = i
					break
			if empty_slot != -1:
				var details = Utils.get_grammarite_details(grammarite_name)
				var new_guy = {
						"Health": Utils.max_hp(grammarite_name, 1), "Item": "", "Level": 1,
						"Moves": [
							details["Moves"][0]["Name"],
							details["Moves"][1]["Name"],
							details["Moves"][2]["Name"],
							details["Moves"][3]["Name"]
						],
						"Name": grammarite_name, "Nickname": "",
						"PP": [
							details["Moves"][0]["PP"],
							details["Moves"][1]["PP"],
							details["Moves"][2]["PP"],
							details["Moves"][3]["PP"],
						]
					}
				
				party[empty_slot] = new_guy
				
				Utils.set_party(party)
			else:
				# Add to storage
				pass
			close_menu()
			queue_free()

func reset():
	await get_tree().create_timer(0.1).timeout
	used_up = false



func _on_body_exited(_body: Node2D) -> void:
	picked_up = false
	used_up = false

func _on_body_entered(_body: Node2D) -> void:
	picked_up = true
