extends Area2D

var picked_up := false
var dialogue_open := false

func _on_body_entered(body):
	if picked_up or dialogue_open:
		return
	if body.is_in_group("Player"):
		dialogue_open = true
		Utils.get_scene_manager().transition_to_dialogue(
			"Pick up",
			"Leave",
		)
		pickup()

func pickup():
	picked_up = true
	visible = false
	$CollisionShape2D.disabled = true

func on_dialogue_closed():
	dialogue_open = false
