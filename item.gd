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

@onready var dialogue_root = $"Pickup Dialogue"

func pickup():
	if !picked_up:
		return
	picked_up = true
	visible = false
	$CollisionShape2D.disabled = true  # disable collision so it can't be triggered again




func _on_body_entered(body: Node2D) -> void:
	picked_up = true
	Utils.get_scene_manager().transition_to_dialogue(dialogue_root, self) 


func _on_body_exited(body: Node2D) -> void:
	picked_up = false
