extends Area2D

var picked_up := false

@onready var dialogue_root = $PickupDialogue

func pickup():
	if !picked_up:
		return
	visible = false
	$CollisionShape2D.disabled = true  # disable collision so it can't be triggered again




func _on_body_entered(body: Node2D) -> void:
	picked_up = true
	Utils.get_scene_manager().transition_to_dialogue(dialogue_root, self) 


func _on_body_exited(body: Node2D) -> void:
	picked_up = false
