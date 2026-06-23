extends Node2D

var next_scene: = ""

var player_location = Vector2(0, 0)
var player_direction = Vector2(0, 0)

var next_trainer = ""

signal name_selected(chosen_name: String, requester_node: Node)
var name_request_node: Node = null

# "New Scene", Naming, Battle, Battle Exit, ... others ...
var transition_type = "New Scene"

@onready var scene = $CurrentScene
@onready var menu =  $Menu
@onready var naming_screen = preload("res://Scenes/NamingScreen.tscn")




func grammadex():
	$Grammadex/AnimationPlayer.play("Grammadex")
	print("Animation")



func transition_to_menu(submenu: String):
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	transition_type = submenu

func transition_exit_menu(submenu: String):
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	
	match submenu:
		"Party", "Item", "Save":
			transition_type = "Menu Only"
		"Computer", "Quest", "Harvester", "Crafter", "Bookshelf":
			transition_type = "Exit Screen"




func transition_to_naming_screen(from_node: Node):
	transition_type = "Naming"
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	name_request_node = from_node
	var namer = naming_screen.instantiate()
	self.add_child(namer)

func transition_to_select_screen():
	return await $GrammariteSelectScreen.load_screen()

func transition_to_dialogue(root_node):
	if menu.screen_loaded == menu.ScreenLoaded.NOTHING:
		$DialogueBox.start_dialogue(root_node)


func load_battle():
	var battle = load("res://Scenes/Battle.tscn").instantiate()
	
	
	if "random" not in next_trainer:
		battle.get_node("BattleManager").trainer = next_trainer
		var trainer = Utils.get_trainer(next_trainer)
		battle.get_node("EnemyGrammarite").grammarite_name = trainer["Party"][0]
		battle.get_node("EnemyGrammarite").level = int(trainer["Levels"][0])
	else:
		battle.get_node("BattleManager").trainer = "random"
		var name_lvl = next_trainer.substr(6) # removes 'random'
		battle.get_node("EnemyGrammarite").grammarite_name = name_lvl.left(len(name_lvl)-3)
		battle.get_node("EnemyGrammarite").level = int(name_lvl.right(3))
	
	scene.add_child(battle)
	scene.get_children().back().get_child(0).make_current()
func transition_to_battle(trainer, gram_name: String = ""):
	next_trainer = trainer+gram_name
	next_scene = $CurrentScene.get_child(0).scene_file_path
	transition_type = "Battle"
	var player = Utils.get_player()
	player.set_physics_process(false)
	player_location = player.position
	player_direction = player.input_direction
	menu.screen_loaded = menu.ScreenLoaded.BATTLE
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
func transition_exit_battle():
	transition_type = "Battle Exit"
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")


func transition_to_scene(new_scene: String, spawn_location, spawn_direction):
	next_scene = new_scene
	player_location = spawn_location
	player_direction = spawn_direction
	transition_type = "New Scene"
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
func transition_to_grammarite_center():
	next_scene = "res://Scenes/GrammariteCenterInside.tscn"
	player_location = Vector2(96,128)
	player_direction = Vector2(0,-1)
	transition_type = "Grammarite Center"
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")


func finished_fading():
	$ScreenTransition/AnimationPlayer.play("FadeToNormal")
	match transition_type:
		"New Scene", "Grammarite Center":
			while scene.get_child_count() > 0:
				scene.get_child(0).free()
			var child = load(next_scene).instantiate()
			
			if transition_type == "Grammarite Center":
				var last_center = Utils.get_last_center()
				child.get_node("Door").next_scene_path = "res://Scenes/"+last_center["Scene"]+".tscn"
				child.get_node("Door").spawn_location = Vector2(last_center["x"], last_center["y"])
				menu.screen_loaded = menu.ScreenLoaded.NOTHING
			
			scene.add_child(child)
			var player = Utils.get_player()
			player.set_spawn(player_location, player_direction)
		
		"Battle":
			load_battle()
		"Battle Exit":
			scene.get_children().back().free()
			var player = Utils.get_player()
			player.set_physics_process(true)
			menu.screen_loaded = menu.ScreenLoaded.NOTHING
		
		"Naming":
			name_selected.emit(await $NamingScreen.load_naming_screen(name_request_node.name_prompt), name_request_node)
		
		"Party", "Item", "Save":
			menu.unload_submenu("Item")
			menu.unload_submenu("Party")
			menu.load_submenu(transition_type)
		"Menu Only":
			menu.unload_submenus(true)
		
		"Exit Screen":
			menu.unload_submenus(false)
			var player = Utils.get_player()
			player.set_physics_process(true)
		"Quest", "Harvester", "Crafter", "Bookshelf", "Computer":
			menu.load_submenu(transition_type)
