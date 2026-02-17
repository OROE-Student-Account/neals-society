extends AnimatedSprite2D


@onready var root_node = $DialogueRoot
@onready var ray = $RayCast2D
@onready var anim_player = $AnimationPlayer

var player_in_range := false
var used_up := false


func approach_until_hit():
	var step = Vector2.ZERO
	step.y = 8
	
	ray.target_position = step
	ray.force_raycast_update()
	
	if not ray.is_colliding():
		position.y += 8
	else:
		anim_player.stop()
		used_up = true
		Utils.get_scene_manager().transition_to_dialogue(root_node)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if used_up: return
	visible = true
	var player = Utils.get_player()
	player.set_physics_process(false)
	player.anim_tree.active = false
	player.anim_player.play("TurnUp")
	$AnimationPlayer.play("Approach")




func _on_hit_box_body_entered(body: Node2D) -> void:
	player_in_range = true

func _on_hit_box_body_exited(body: Node2D) -> void:
	player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	var player = Utils.get_player()
	if  not used_up and player.can_interact_with_object and event.is_action_pressed("z") and player_in_range:
		used_up = true
		
		var player_facing = player.facing_direction
		if player_facing == 0:
			anim_player.play("TurnRight")
		if player_facing == 1:
			anim_player.play("TurnLeft")
		if player_facing == 3:
			anim_player.play("TurnAround")
		
		Utils.get_scene_manager().transition_to_dialogue(root_node)
