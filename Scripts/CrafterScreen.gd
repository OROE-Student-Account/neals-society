extends Node2D

enum Page { MAIN, SWITCH }
var page = Page.MAIN

enum Options { SWITCH1, SWITCH2, CRAFT, CANCEL }
var selected_option = 0

@onready var empty = preload("res://Assets/UI/Plain/Empty.png")

@onready var buttons = $Buttons
@onready var shard_select = $ShardSelect

var shard1 = ""
var shard2 = ""


const TYPES = [
	"Grammar",
	"Literature",
	"Homework",
	"Slang",
	"Paper",
	"Nature",
	"Supply",
	"Knowledge",
	"Ink",
	"Animal",
	"Machine"
]

const BORDER_POSITIONS = [
	Vector2(72,60),
	Vector2(104,60),
	Vector2(136,60),
	Vector2(168,60),
	Vector2(88,92),
	Vector2(120,92),
	Vector2(152,92),
	Vector2(72,124),
	Vector2(104,124),
	Vector2(136,124),
	Vector2(168,124)
]


func _ready() -> void:
	$Animation.visible = false
	update_buttons()
	update_screen()
	load_shards()
	
	$Control/Label2.text = "None"
	$Control/Label3.text = "None"



func update_screen():
	match page:
		Page.MAIN:
			shard_select.visible = false
		Page.SWITCH:
			shard_select.visible = true

func update_buttons():
	match page:
		Page.MAIN:
			for butt in buttons.get_children():
				butt.frame = 0
			buttons.get_child(selected_option).frame = 1
			if shard1 != "":
				$Control/Shard1.texture = load("res://Assets/Items/"+shard1+" Shard.png")
				$Animation/Shard1.texture = load("res://Assets/Items/"+shard1+" Shard.png")
			else:
				$Control/Shard1.texture = empty
			if shard2 != "":
				$Control/Shard2.texture = load("res://Assets/Items/"+shard2+" Shard.png")
				$Animation/Shard2.texture = load("res://Assets/Items/"+shard2+" Shard.png")
			else:
				$Control/Shard2.texture = empty
		Page.SWITCH:
			shard_select.get_node("Border").position = BORDER_POSITIONS[selected_option]
			shard_select.get_node("Label").text = "Count: "+str(count_shard(TYPES[selected_option]))


func select_shard():
	page = Page.SWITCH
	selected_option = 0
	update_screen()
	update_buttons()
	
	while page == Page.SWITCH:
		await get_tree().process_frame
	

	var shard = selected_option
	if selected_option == -1 or count_shard(TYPES[selected_option]) < 1 or shard1 == TYPES[selected_option] or shard2 == TYPES[selected_option]:
		shard = -1
	
	selected_option = 0
	update_screen()
	update_buttons()
	
	return shard

func load_shards():
	for i in range(len(TYPES)):
		var shard = Sprite2D.new()
		shard.texture = load("res://Assets/Items/"+TYPES[i]+" Shard.png")
		shard.position = BORDER_POSITIONS[i]+Vector2(1,0)
		shard.scale = Vector2(0.916, 0.916) # probably bad and should fix, but small shrink to look good
		shard_select.add_child(shard)

func count_shard(item):
	var count = 0
	while Utils.remove_from_inventory(item+" Shard"):
		count += 1
	
	for i in range(count):
		Utils.add_to_inventory(item+" Shard")
	
	return count

func craft():
	if shard1 != "" and shard2 != "":
		
		var craftable = true # flag for if inventory is full so you can't craft
		
		
		var thing = Utils.get_recipe(shard1, shard2) # what you craft
		
		if thing != {}:
			if thing["Type"] == "Item":
				$Animation/Grammarite.texture = empty
				$Animation/Item.texture = load("res://Assets/Items/"+thing["Name"]+".png")
				Utils.add_to_inventory(thing["Name"])
			elif thing["Type"] == "Grammarite":
				$Animation/Item.texture = empty
				$Animation/Grammarite.texture = load("res://Assets/Pokemon/Pokemon"+str(1+Utils.get_poke_num(thing["Name"]))+".png")
				var found = false # flag for if there is room in inventory
				
				# sets up the grammarite
				var g_name = thing["Name"]
				var details = Utils.get_grammarite_details(g_name)
				var grammarite = {
					"Health": Utils.max_hp(g_name, 1),
					"Item": "",
					"Level": 1.0,
					"Moves": [],
					"Name": g_name,
					"Nickname": "",
					"PP": []
				}
				for i in range(4):
					grammarite["Moves"].append(details["Moves"][i]["Name"])
					grammarite["PP"].append(details["Moves"][i]["PP"])
				
				# checks party for a spot
				var party = Utils.get_party()
				for i in range(6):
					if party[i]["Name"] == "":
						party[i] = grammarite
						found = true
						Utils.set_party(party)
						break
				
				if not found:
					# checks for room on bookshelf
					if not Utils.add_to_bookshelf(grammarite):
						craftable =  false
				
			if craftable:
				# craft animation
				$Animation/AnimationPlayer.play("Craft")
				await get_tree().create_timer(5.0).timeout
				
				Utils.remove_from_inventory(shard1+" Shard")
				shard1 = ""
				Utils.remove_from_inventory(shard2+" Shard")
				shard2 = ""
				$Control/Label2.text = "None"
				$Control/Label3.text = "None"
				update_buttons()
			else:
				$Animation/AnimationPlayer.play("Fail")
				shard1 = ""
				shard2 = ""
				$Control/Label2.text = "None"
				$Control/Label3.text = "None"
				update_buttons()

func _input(event):
	match page:
		Page.MAIN:
			if event.is_action_pressed("ui_up"):
				if selected_option > Options.SWITCH2:
					selected_option -= 2
				update_buttons()
				
			elif event.is_action_pressed("ui_down"):
				if selected_option < Options.CRAFT:
					selected_option = Options.CRAFT
				update_buttons()
				
			elif event.is_action_pressed("ui_right"):
				if selected_option == Options.SWITCH1:
					selected_option = Options.SWITCH2
				elif selected_option == Options.CRAFT:
					selected_option = Options.CANCEL
				update_buttons()
				
			elif event.is_action_pressed("ui_left"):
				if selected_option == Options.SWITCH2:
					selected_option = Options.SWITCH1
				elif selected_option == Options.CANCEL:
					selected_option = Options.CRAFT
				update_buttons()
				
			elif event.is_action_pressed("x") or (event.is_action_pressed("z") and selected_option == Options.CANCEL):
				Utils.get_scene_manager().transition_exit_menu("Crafter")
				
			elif event.is_action_pressed("z"):
				if selected_option == Options.SWITCH1:
					var index = await select_shard()
					if index != -1:
						shard1 = TYPES[index]
						$Control/Label2.text = shard1
					update_buttons()
				elif selected_option == Options.SWITCH2:
					var index = await select_shard()
					if index != -1:
						shard2 = TYPES[index]
						$Control/Label3.text = shard2
					selected_option = Options.SWITCH2
					update_buttons()
				elif selected_option == Options.CRAFT:
					craft()
					
		Page.SWITCH:
			if event.is_action_pressed("ui_up"):
				if selected_option > 7:
					selected_option -= 4
				elif selected_option > 3:
					selected_option -= 3
				update_buttons()
			elif event.is_action_pressed("ui_down"):
				if selected_option < 3:
					selected_option += 4
				elif selected_option < 7:
					selected_option += 3
				update_buttons()
			elif event.is_action_pressed("ui_right"):
				if selected_option != 3 and selected_option != 6 and selected_option != 10:
					selected_option += 1
				update_buttons()
			elif event.is_action_pressed("ui_left"):
				if selected_option != 0 and selected_option != 4 and selected_option != 7:
					selected_option -= 1
				update_buttons()
			
			elif event.is_action_pressed("z"):
				page = Page.MAIN
			
			elif event.is_action_pressed("x"):
				page = Page.MAIN
				selected_option = -1
