extends Node2D

enum Options { CRUSH, SWITCH, CANCEL }
var selected_option = 0

var slot_to_crush = 0

@onready var buttons = $Buttons
@onready var display = $Display
@onready var animation = $Animation

var pause = false

func _ready() -> void:
	animation.visible = false
	update_buttons()
	update_display()

func update_display():
	var slot = Utils.get_party()[slot_to_crush]
	display.get_node("Sprite2D").texture = load("res://Assets/Pokemon/Pokemon"+str(Utils.get_poke_num(slot["Name"])+1)+".png")
	animation.get_node("Sprite2D").texture = load("res://Assets/Pokemon/Pokemon"+str(Utils.get_poke_num(slot["Name"])+1)+".png")
	if slot["Nickname"] == "":
		display.get_node("Label").text = slot["Name"]
	else:
		display.get_node("Label").text = slot["Nickname"]

func update_buttons():
	for butt in buttons.get_children():
		butt.frame = 0
	buttons.get_child(selected_option).frame = 1

func crush():
	pause = true
	
	var party = Utils.get_party()
	
	var count = 0
	for g in party:
		if g["Name"] != "":
			count += 1
	
	animation.visible = true
	
	if count > 1:
		var grammarite = Utils.get_grammarite_details(party[slot_to_crush]["Name"])
		var shard_type = grammarite["Stats"]["Types"].pick_random()
		Utils.add_to_inventory(shard_type+" Shard")
		
		for i in range(slot_to_crush, 5): 
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
		
		Utils.set_party(party)
		
		animation.get_node("AnimationPlayer").play("Crush")
		await get_tree().create_timer(4.0).timeout
		
		animation.get_node("Label").text = "You got a "+shard_type+" Shard!"
	else:
		animation.get_node("Label").text = "Get a larger party before harvesting shards."
	
	animation.get_node("AnimationPlayer").play("Label")
	await get_tree().create_timer(1.5).timeout
	
	animation.visible = false
	pause = false
	selected_option = 0
	slot_to_crush = 0
	update_buttons()
	update_display()

func _input(event):
	if pause: return
	if event.is_action_pressed("ui_up"):
		if selected_option != Options.CRUSH:
			selected_option -= 1
		update_buttons()
		
	elif event.is_action_pressed("ui_down"):
		if selected_option != Options.CANCEL:
			selected_option += 1
		update_buttons()
		
	elif event.is_action_pressed("x") or (event.is_action_pressed("z") and selected_option == Options.CANCEL):
		Utils.get_scene_manager().transition_exit_harvester()
		
	elif event.is_action_pressed("z"):
		if selected_option == Options.CRUSH:
			crush()
		elif selected_option == Options.SWITCH:
			pause = true
			var index = await Utils.get_scene_manager().transition_to_select_screen()
			pause = false
			slot_to_crush = index
			update_display()
