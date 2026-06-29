extends Area2D


@export var func_node : Node2D = null

@onready var root_node = $DialogueRoot

var player_in_range := false
var disabled := false
var used_up


func _ready():
	var scene = Utils.get_scene_manager().get_node("CurrentScene").get_child(0).name
	$Sprite2D.frame = 0
	if Utils.check_trainer_attacked(name, scene):
		used_up = true
		$Sprite2D.frame = 1
		
	Utils.get_scene_manager().get_node("DialogueBox").connect("dialogue_ended", Callable(self, "reset"))


func reset():
	disabled = true
	await get_tree().create_timer(0.1).timeout
	disabled = false



func _on_body_entered(body: Node2D) -> void:
	player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	player_in_range = false


func pull():
	used_up = true
	var scene = get_node("/root/SceneManager/CurrentScene").get_child(0).name
	Utils.update_trainer_attacked(name, true, scene)
	$Sprite2D.frame = 1
	func_node.broken()

func _unhandled_input(event: InputEvent) -> void:
	if disabled or used_up: return
	if Utils.get_scene_manager().get_node("Menu").screen_loaded != 0: return
	
	var player = Utils.get_player()
	if player_in_range and event.is_action_pressed("z") and player.can_interact_with_object:
		
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
		
		disabled = true
		
		Utils.get_scene_manager().transition_to_dialogue(root_node)
