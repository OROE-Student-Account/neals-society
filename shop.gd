extends Sprite2D

var picked_up = false
var used_up = false

@onready var dialogue_root = $DialogueRoot

func _ready() -> void:
	Utils.get_scene_manager().get_node("Menu").connect("close_menu", Callable(self, "reset"))


func open_machine():
	var player = Utils.get_player()
	player.set_physics_process(false)
	
	if name == "Quest Board":
		Utils.get_scene_manager().transition_to_menu("Quest")
	else:
		Utils.get_scene_manager().transition_to_menu(name)


func _unhandled_input(event: InputEvent) -> void:
	var player = Utils.get_player()
	if player.can_interact_with_object and event.is_action_pressed("z") and picked_up and !used_up:
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
		
		used_up = true
		
		Utils.get_scene_manager().transition_to_dialogue(dialogue_root) 

func reset():
	await get_tree().create_timer(0.1).timeout
	used_up = false

func _on_area_body_entered(body: Node2D) -> void:
	picked_up = true


func _on_area_body_exited(body: Node2D) -> void:
	picked_up = false
	used_up = false
