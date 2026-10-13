extends Area2D

@export var id: int = 0
@onready var puzzle_scene = preload("res://Scenes/Specialized/WirePuzzle.tscn") # Assign your new UI scene here in the inspector

var player_in_range := false
var disabled := false

func _ready():
	Utils.get_scene_manager().get_node("DialogueBox").connect("dialogue_ended", Callable(self, "reset"))

func reset():
	disabled = true
	await get_tree().create_timer(0.1).timeout
	disabled = false

func _on_body_entered(_body: Node2D) -> void:
	player_in_range = true

func _on_body_exited(_body: Node2D) -> void:
	player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if disabled: return
	if Utils.get_scene_manager().get_node("Menu").screen_loaded != 0: return
	
	var player = Utils.get_player()
	if player_in_range and event.is_action_pressed("z") and player.can_interact_with_object:
		
		var player_facing = player.facing_direction
		var player_pos = player.position
		if player_facing != 0 && player_pos.x > position.x && player_pos.y == position.y: return
		if player_facing != 1 && player_pos.x < position.x && player_pos.y == position.y: return
		if player_facing != 2 && player_pos.x == position.x && player_pos.y > position.y: return
		if player_facing != 3 && player_pos.x == position.x && player_pos.y < position.y: return
		
		disabled = true
		player.set_physics_process(false)
		
		# --- THE KEYCARD CHECK ---
		if Utils.remove_from_inventory("Keycard"):
			Utils.add_to_inventory("Keycard")
			_start_wire_puzzle()
		else:
			Utils.get_scene_manager().transition_to_dialogue($FailedToOpen)

func _start_wire_puzzle() -> void:
	if puzzle_scene:
		var puzzle = puzzle_scene.instantiate()
		
		# Listen for when the player quits or wins so we can unlock the player's movement
		# --- THE FIX: Godot 4 Direct Signal Connections ---
		
		puzzle.get_child(0).connect("puzzle_exited", Callable(self, "_on_puzzle_closed"))
		puzzle.get_child(0).connect("puzzle_completed", Callable(self, "_on_puzzle_closed"))
		
		Utils.get_scene_manager().get_node("CurrentScene").add_child(puzzle)
	else:
		print("Error: No puzzle scene assigned to the Box!")
		Utils.get_player().set_physics_process(true)
		reset()

func _on_puzzle_closed() -> void:
	print("tets")
	reset()
