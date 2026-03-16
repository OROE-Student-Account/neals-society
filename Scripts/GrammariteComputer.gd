extends Area2D

var picked_up = false
var in_menu = false

@onready var dialogue_root = $DialogueRoot

@onready var menu_scene = preload("res://Scenes/GrammariteStorage.tscn")


func open_grammarite_storage():
	var player = Utils.get_player()
	player.set_physics_process(false)
	in_menu = true
	
	Utils.get_scene_manager().get_node("CurrentScene").add_child(menu_scene.instantiate())


func _unhandled_input(event: InputEvent) -> void:
	var player = Utils.get_player()
	if player.can_interact_with_object and event.is_action_pressed("z") and picked_up and !in_menu:
		
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
		
		Utils.get_scene_manager().transition_to_dialogue(dialogue_root) 


func _on_body_entered(body: Node2D) -> void:
	picked_up = true


func _on_body_exited(body: Node2D) -> void:
	picked_up = false
