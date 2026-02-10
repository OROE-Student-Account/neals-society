extends AnimatedSprite2D

@export var root_node: Node = null # root of the dialogue tree
@export var func_node: Node = null

@onready var ray = $RayCast2D

func _ready():
	pass
	

func approach_until_hit():
	var step = Vector2.ZERO
	step.y = 8
	
	ray.target_position = step
	ray.force_raycast_update()
	
	if not ray.is_colliding():
		position.y += 8
	else:
		$AnimationPlayer.stop()
		
		Utils.get_scene_manager().transition_to_dialogue(root_node, func_node)

func _on_area_2d_body_entered(body: Node2D) -> void:
	visible = true
	var player = Utils.get_player()
	player.set_physics_process(false)
	player.anim_tree.active = false
	player.anim_player.play("TurnUp")
	$AnimationPlayer.play("Approach")
