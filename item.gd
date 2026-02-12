extends Area2D

var picked_up = false

@onready var dialogue_root = $"Pickup Dialogue"

func pickup():
	if !picked_up:
		return
	picked_up = true
	visible = false
	$CollisionShape2D.disabled = true  # disable collision so it can't be triggered again
	
	# Fix this. It should have a function node
	# Your choice to pick it up or not should matter




func _on_body_entered(body: Node2D) -> void:
	picked_up = true
	Utils.get_scene_manager().transition_to_dialogue(dialogue_root, self) 


func _on_body_exited(body: Node2D) -> void:
	picked_up = false
