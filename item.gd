extends Area2D

var picked_up = false

func pickup():
	if picked_up:
		return  # safety check so we don't pick up twice
	picked_up = true
	visible = false
	$CollisionShape2D.disabled = true  # disable collision so it can't be triggered again
	Utils.get_scene_manager().transition_to_dialogue("Pick up", "Leave")


func _on_body_entered(body: Node2D) -> void:
	pickup()


func _on_body_exited(body: Node2D) -> void:
	# nothing necessary rn
	pass
