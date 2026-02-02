extends Area2D


var picked_up = false

func pickup():
	visible = false
	Utils.get_scene_manager().transition_to_dialogue("Pick up", "Leave")



func _on_body_entered(body: Node2D) -> void:
	pickup()


func _on_body_exited(body: Node2D) -> void:
	if not picked_up:
		visible = true
