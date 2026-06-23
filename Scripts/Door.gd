extends Area2D

@export var next_scene_path = "" # (String, FILE)
@export var is_invisible: bool = false
@export var texture : Texture2D = null

@export var spawn_location: Vector2 = Vector2(0, 0)
@export var spawn_direction: Vector2 = Vector2(0, 0)

@onready var sprite = $Sprite2D
@onready var anim_player = $AnimationPlayer

var player_entered = false

func _ready():
	if texture != null:
		sprite.texture = texture
	
	if is_invisible:
		sprite.texture = null
	sprite.visible = false
	var player = Utils.get_player()
	
	player.connect("player_entering_door_signal", Callable(self, "enter_door"))
	player.connect("player_entered_door_signal", Callable(self, "close_door"))

func enter_door():
	if player_entered:
		anim_player.play("OpenDoor")
	
func close_door():
	if player_entered:
		anim_player.play("CloseDoor")

func door_closed():
	if player_entered:
		if next_scene_path == "res://Scenes/GrammariteCenterInside.tscn":
			var last_center = str(get_parent().name)[-1] # gets the number of this center
			Utils.set_last_center(int(last_center))
			Utils.get_scene_manager().transition_to_grammarite_center()
		else:
			Utils.get_scene_manager().transition_to_scene(next_scene_path, spawn_location, spawn_direction)


func _on_body_entered(_body: Node2D) -> void:
	player_entered = true


func _on_body_exited(_body: Node2D) -> void:
	player_entered = false
