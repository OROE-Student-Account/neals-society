extends AnimatedSprite2D


@onready var root_node = $DialogueRoot
@onready var ray = $RayCast2D
@onready var anim_player = $AnimationPlayer
@onready var final_dialogue = $FinalDialogue

var player_in_range := false
var used_up := false
var disabled := false


func _ready():
	var scene = Utils.get_scene_manager().get_node("CurrentScene").get_child(0).name
	if Utils.check_trainer_attacked(name, scene):
		used_up = true
	
	Utils.get_scene_manager().get_node("DialogueBox").connect("dialogue_ended", Callable(self, "reset"))


func approach_until_hit():
	var step = Vector2.ZERO
	step.y = 16
	
	ray.target_position = step
	ray.force_raycast_update()
	
	if not ray.is_colliding():
		position.y += 8
	else:
		anim_player.stop()
		used_up = true
		var scene = get_node("/root/SceneManager/CurrentScene").get_child(0).name
		Utils.update_trainer_attacked(name, true, scene)
		Utils.get_scene_manager().transition_to_dialogue(root_node)

func _on_area_2d_body_entered(_body: Node2D) -> void:
	if used_up: return
	
	visible = true
	var player = Utils.get_player()
	player.set_physics_process(false)
	player.anim_tree.active = false
	player.anim_player.play("TurnUp")
	$AnimationPlayer.play("Approach")


func reset():
	disabled = true
	await get_tree().create_timer(0.1).timeout
	disabled = false

func used_up_dialogue():
	disabled = true
	Utils.get_scene_manager().transition_to_dialogue(final_dialogue)



func _on_hit_box_body_entered(_body: Node2D) -> void:
	player_in_range = true

func _on_hit_box_body_exited(_body: Node2D) -> void:
	player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if disabled: return
	if Utils.get_scene_manager().get_node("Menu").screen_loaded != 0: return
	
	var player = Utils.get_player()
	if player_in_range and event.is_action_pressed("z") and player.can_interact_with_object:
		
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
		
		if player_facing == 0:
			anim_player.play("TurnRight")
		if player_facing == 1:
			anim_player.play("TurnLeft")
		if player_facing == 2:
			anim_player.play("TurnDown")
		if player_facing == 3:
			anim_player.play("TurnAround")
		
		if used_up: 
			used_up_dialogue()
			return
		
		used_up = true
		disabled = true
		var scene = get_node("/root/SceneManager/CurrentScene").get_child(0).name
		Utils.update_trainer_attacked(name, true, scene)
		
		Utils.get_scene_manager().transition_to_dialogue(root_node)
