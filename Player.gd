extends CharacterBody2D

signal player_moving_signal
signal player_stop_signal
signal player_entering_door_signal
signal player_entered_door_signal

const LandingDustEffect = preload("res://LandingDustEffect.tscn")

@export var walk_speed = 6.0
@export var jump_speed = 4.0
const TILE_SIZE = 16

@onready var anim_tree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

@onready var ray = $BlockingRayCast2D
@onready var ledge_ray = $LedgeRayCast2D
@onready var door_ray = $DoorRayCast2D

@onready var shadow = $Shadow
@onready var sprite = $PlayerSprite

var entering_door := false
var jumping_over_ledge := false

enum PlayerState { IDLE, TURNING, WALKING }
enum FacingDirection { LEFT, RIGHT, UP, DOWN }

var player_state = PlayerState.IDLE
var facing_direction = FacingDirection.DOWN

var initial_position := Vector2.ZERO
var input_direction := Vector2(0,0)
var is_moving := false
var stop_input := false
var percent_moved_to_next_tile := 0.0

func _ready():
	add_to_group("Player")
	
	sprite.visible = true
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2.ONE

	if has_node("Camera2D"):
		$Camera2D.make_current()

	anim_tree.active = true
	initial_position = position
	shadow.visible = false

func set_spawn(location: Vector2, direction: Vector2):
	entering_door = false
	jumping_over_ledge = false
	is_moving = false
	stop_input = false
	percent_moved_to_next_tile = 0.0
	input_direction = direction
	position = location
	initial_position = location
	sprite.visible = true
	anim_state.travel("Idle")



func _physics_process(delta):
	if stop_input or player_state == PlayerState.TURNING:
		return
	elif not is_moving:
		process_player_input()
	elif input_direction != Vector2.ZERO:
		anim_state.travel("Walk")
		move(delta)
	else:
		anim_state.travel("Idle")
		is_moving = false

func process_player_input():
	input_direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right") != Input.is_action_pressed("ui_left"):
		input_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	elif Input.is_action_pressed("ui_down") != Input.is_action_pressed("ui_up"):
		input_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))

	if input_direction != Vector2.ZERO:
		anim_tree.set("parameters/Idle/blend_position", input_direction)
		anim_tree.set("parameters/Walk/blend_position", input_direction)
		anim_tree.set("parameters/Turn/blend_position", input_direction)
		
		if need_to_turn():
			player_state = PlayerState.TURNING
			anim_state.travel("Turn")
		else:
			initial_position = global_position
			is_moving = true
	else:
		anim_state.travel("Idle")

func need_to_turn() -> bool:
	var new_dir
	if input_direction.x < 0: new_dir = FacingDirection.LEFT
	elif input_direction.x > 0: new_dir = FacingDirection.RIGHT
	elif input_direction.y < 0: new_dir = FacingDirection.UP
	elif input_direction.y > 0: new_dir = FacingDirection.DOWN

	if new_dir != facing_direction:
		facing_direction = new_dir
		return true
	return false

func finished_turning():
	player_state = PlayerState.IDLE

func move(delta):
	var step := input_direction * TILE_SIZE / 2
	ray.target_position = step
	ledge_ray.target_position = step
	door_ray.target_position = step
	ray.force_raycast_update()
	ledge_ray.force_raycast_update()
	door_ray.force_raycast_update()

	# --- Door ---
	if door_ray.is_colliding() and not entering_door:
		entering_door = true
		percent_moved_to_next_tile = 0.0
		emit_signal("player_entering_door_signal")

	if entering_door:
		percent_moved_to_next_tile += walk_speed * delta
		if percent_moved_to_next_tile >= 1.0:
			position = initial_position + input_direction * TILE_SIZE
			entering_door = false
			is_moving = false
			percent_moved_to_next_tile = 0.0
			emit_signal("player_entered_door_signal")
		else:
			position = initial_position + input_direction * TILE_SIZE * percent_moved_to_next_tile

	# --- Ledge ---
	elif (ledge_ray.is_colliding() and input_direction == Vector2.DOWN) or jumping_over_ledge:
		percent_moved_to_next_tile += jump_speed * delta
		if percent_moved_to_next_tile >= 2.0:
			position = initial_position + input_direction * TILE_SIZE * 2
			jumping_over_ledge = false
			percent_moved_to_next_tile = 0.0
			is_moving = false
			shadow.visible = false
			var dust_effect = LandingDustEffect.instantiate()
			dust_effect.position = position
			get_tree().current_scene.add_child(dust_effect)
		else:
			jumping_over_ledge = true
			shadow.visible = true
			var input = input_direction.y * TILE_SIZE * percent_moved_to_next_tile
			position.y = initial_position.y + (-0.96 - 0.53 * input + 0.05 * pow(input, 2))
			

	# --- Normal ---
	elif not ray.is_colliding():
		if percent_moved_to_next_tile == 0:
			emit_signal("player_moving_signal")
		percent_moved_to_next_tile += walk_speed * delta
		if percent_moved_to_next_tile >= 1.0:
			position = initial_position + input_direction * TILE_SIZE
			is_moving = false
			percent_moved_to_next_tile = 0.0
			emit_signal("player_stop_signal")
		else:
			position = initial_position + input_direction * TILE_SIZE * percent_moved_to_next_tile
	else:
		is_moving = false
