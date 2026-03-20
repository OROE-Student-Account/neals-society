extends Area2D

var picked_up := false
var used_up := false
var opened := false

@onready var dialogue_root = $PickupDialogue

@export var item_name := ""


func _ready() -> void:
	var scene = get_node("/root/SceneManager/CurrentScene").get_child(0).name
	if Utils.check_item_picked_up(name, scene):
		opened = true
		$Sprite2D.frame = 1
	
	visible = true


func pickup():
	if !picked_up:
		return
	if item_name != "":
		Utils.add_to_inventory(item_name)
	var scene = get_node("/root/SceneManager/CurrentScene").get_child(0).name
	Utils.update_item_picked_up(name, true, scene)
	opened = true
	$Sprite2D.frame = 1

func reset():
	await get_tree().create_timer(0.1).timeout
	used_up = false


func _unhandled_input(event: InputEvent) -> void:
	if opened: return
	var player = Utils.get_player()
	if player.can_interact_with_object and event.is_action_pressed("z") and picked_up and not used_up:
		
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
		Utils.get_scene_manager().transition_to_dialogue(dialogue_root) 




func _on_body_entered(_body: Node2D) -> void:
	picked_up = true


func _on_body_exited(_body: Node2D) -> void:
	picked_up = false
	used_up = false
