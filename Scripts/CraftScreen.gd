extends Node2D

enum Page { MAIN, SWITCH }
var page = Page.MAIN

enum Options { SWITCH1, SWITCH2, CRAFT, CANCEL }
var selected_option = 0

@onready var buttons = $Buttons
@onready var shard_select = $ShardSelect

var shard1 = ""
var shard2 = ""


var types = [
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

var border_positions = [
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
	update_buttons()
	update_screen()
	load_shards()



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
			if shard2 != "":
				$Control/Shard2.texture = load("res://Assets/Items/"+shard2+" Shard.png")
		Page.SWITCH:
			shard_select.get_node("Border").position = border_positions[selected_option]
			shard_select.get_node("Label").text = "Count: "+str(count_shard(types[selected_option]))


func select_shard():
	page = Page.SWITCH
	selected_option = 0
	update_screen()
	update_buttons()
	
	while page == Page.SWITCH:
		await get_tree().process_frame
	
	var shard = selected_option
	
	selected_option = 0
	update_screen()
	update_buttons()
	
	return types[shard]

func load_shards():
	for i in range(len(types)):
		var shard = Sprite2D.new()
		shard.texture = load("res://Assets/Items/"+types[i]+" Shard.png")
		shard.position = border_positions[i]+Vector2(1,0)
		shard.scale = Vector2(0.916, 0.916)
		shard_select.add_child(shard)

func count_shard(item):
	var count = 0
	while Utils.remove_from_inventory(item+" Shard"):
		count += 1
	
	for i in range(count):
		Utils.add_to_inventory(item+" Shard")
	
	return count


func _input(event):
	match page:
		Page.MAIN:
			if event.is_action_pressed("ui_up"):
				if selected_option > Options.SWITCH2:
					selected_option -= 2
				update_buttons()
				
			elif event.is_action_pressed("ui_down"):
				if selected_option < Options.CRAFT:
					selected_option += 2
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
				Utils.get_scene_manager().transition_exit_crafter()
				
			elif event.is_action_pressed("z"):
				if selected_option == Options.SWITCH1:
					shard1 = await select_shard()
					update_buttons()
				elif selected_option == Options.SWITCH2:
					shard2 = await select_shard()
					selected_option = Options.SWITCH2
					update_buttons()
				elif selected_option == Options.CRAFT:
					pass
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
				if count_shard(types[selected_option]) > 0:
					if shard1 != types[selected_option] and shard2 != types[selected_option]:
						page = Page.MAIN
