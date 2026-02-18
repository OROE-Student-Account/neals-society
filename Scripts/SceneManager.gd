extends Node2D

var next_scene: = ""

var player_location = Vector2(0, 0)
var player_direction = Vector2(0, 0)

enum TransitionType { NEW_SCENE, PARTY_SCREEN, MENU_ONLY, BATTLE, BATTLE_EXIT }
var transition_type = TransitionType.NEW_SCENE

@onready var scene = $CurrentScene

# Called when the node enters the scene tree for the first time.
func _ready():
	Utils.reset_town()

func transition_to_party_screen():
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	transition_type = TransitionType.PARTY_SCREEN
	
func transition_exit_party_screen():
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")
	transition_type = TransitionType.MENU_ONLY

func transition_to_dialogue(root_node):
	$DialogueBox.start_dialogue(root_node)

func transition_to_battle():
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
	match transition_type:
		TransitionType.NEW_SCENE:
			scene.get_child(0).free()
			scene.add_child(load(next_scene).instantiate())
			var player = Utils.get_player()
			player.set_spawn(player_location, player_direction)
		TransitionType.PARTY_SCREEN:
			$Menu.load_party_screen()
		TransitionType.MENU_ONLY:
			$Menu.unload_party_screen()
		TransitionType.BATTLE:
			scene.add_child(load("res://Scenes/Battle.tscn").instantiate())
			scene.get_children().back().get_child(0).make_current()
		TransitionType.BATTLE_EXIT:
			scene.get_children().back().free()
			var player = Utils.get_player()
			player.set_physics_process(true)
	
	$ScreenTransition/AnimationPlayer.play("FadeToNormal")
