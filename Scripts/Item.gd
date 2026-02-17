extends Area2D

var picked_up := false
var used_up := false

@onready var dialogue_root = $PickupDialogue

@export var item_name := ""

func pickup():
	print
	if !picked_up:
		return
	if item_name != "":
		Utils.add_to_inventory(item_name)
	self.queue_free()




func _unhandled_input(event: InputEvent) -> void:
	var player = Utils.get_player()
	if player.can_interact_with_object and event.is_action_pressed("z") and picked_up and not used_up:
		used_up = true
		Utils.get_scene_manager().transition_to_dialogue(dialogue_root) 




func _on_body_entered(body: Node2D) -> void:
	picked_up = true


func _on_body_exited(body: Node2D) -> void:
	picked_up = false
	used_up = false
