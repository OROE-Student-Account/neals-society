extends Node2D

var next_scene: = ""

var player_location = Vector2(0, 0)
var player_direction = Vector2(0, 0)

var next_trainer = ""

signal name_selected(chosen_name: String, requester_node: Node)
var name_request_node: Node = null

enum TransitionType { NEW_SCENE, PARTY_SCREEN, ITEM_SCREEN, MENU_ONLY, BATTLE, BATTLE_EXIT, STORAGE, EXIT_STORAGE, NAMING }
var transition_type = TransitionType.NEW_SCENE

@onready var scene = $CurrentScene



func transition_to_party_screen():
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	transition_type = TransitionType.PARTY_SCREEN
func transition_exit_party_screen():
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	transition_type = TransitionType.MENU_ONLY

func transition_to_item_screen():
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	transition_type = TransitionType.ITEM_SCREEN
func transition_exit_item_screen():
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	transition_type = TransitionType.MENU_ONLY

func transition_to_grammarite_storage():
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	transition_type = TransitionType.STORAGE
func transition_exit_grammarite_storage():
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	transition_type = TransitionType.EXIT_STORAGE


func transition_to_naming_screen(from_node: Node):
	transition_type = TransitionType.NAMING
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	name_request_node = from_node


func transition_to_select_screen():
	return await $GrammariteSelectScreen.load_screen()


func transition_to_dialogue(root_node):
	$DialogueBox.start_dialogue(root_node)


func load_battle():
	var battle = load("res://Scenes/Battle.tscn").instantiate()
	battle.get_node("BattleManager").trainer = next_trainer
	
	if next_trainer != "random":
		var trainer = Utils.get_trainer(next_trainer)
		battle.get_node("EnemyGrammarite").grammarite_name = trainer["Party"][0]
		battle.get_node("EnemyGrammarite").level = int(trainer["Levels"][0])
	else:
		var grammarite = Utils.get_random_grammarite()
		battle.get_node("EnemyGrammarite").grammarite_name = grammarite
		battle.get_node("EnemyGrammarite").level = int(randf()*100+1)
	
	scene.add_child(battle)
	scene.get_children().back().get_child(0).make_current()

func transition_to_battle(trainer):
	next_trainer = trainer
	next_scene = $CurrentScene.get_child(0).scene_file_path
	transition_type = TransitionType.BATTLE
	var player = Utils.get_player()
	player.set_physics_process(false)
	player_location = player.position
	player_direction = player.input_direction
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")

func transition_exit_battle():
	transition_type = TransitionType.BATTLE_EXIT
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")


func transition_to_scene(new_scene: String, spawn_location, spawn_direction):
	next_scene = new_scene
	player_location = spawn_location
	player_direction = spawn_direction
	transition_type = TransitionType.NEW_SCENE
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")


func finished_fading():
	$ScreenTransition/AnimationPlayer.play("FadeToNormal")
	match transition_type:
		TransitionType.NEW_SCENE:
			scene.get_child(0).free()
			scene.add_child(load(next_scene).instantiate())
			var player = Utils.get_player()
			player.set_spawn(player_location, player_direction)
		TransitionType.PARTY_SCREEN:
			$Menu.unload_item_screen()
			$Menu.load_party_screen()
		TransitionType.ITEM_SCREEN:
			$Menu.unload_party_screen()
			$Menu.load_item_screen()
		TransitionType.MENU_ONLY:
			$Menu.unload_party_screen()
			$Menu.unload_item_screen()
		TransitionType.BATTLE:
			load_battle()
			$Menu.screen_loaded = 7
		TransitionType.BATTLE_EXIT:
			scene.get_children().back().free()
			var player = Utils.get_player()
			player.set_physics_process(true)
			$Menu.screen_loaded = 0
		TransitionType.STORAGE:
			$Menu.load_storage_screen()
		TransitionType.EXIT_STORAGE:
			$Menu.unload_storage_screen()
			var player = Utils.get_player()
			player.set_physics_process(true)
		TransitionType.NAMING:
			name_selected.emit(await $NamingScreen.load_naming_screen(name_request_node.name_prompt), name_request_node)
