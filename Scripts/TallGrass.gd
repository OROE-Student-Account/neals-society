extends Node2D

@onready var anim_player = $AnimationPlayer
const grass_overlay_texture = preload("res://Assets/Grass/stepped_tall_grass.png")
const GrassStepEffect = preload("res://Scenes/GrassStepEffect.tscn")

var grass_overlay: Node2D = null


# Called when the node enters the scene tree for the first time.
func _ready():
	var player = Utils.get_player()
	player.connect("player_moving_signal", Callable(self, "player_exiting_grass"))

func player_exiting_grass():
	if is_instance_valid(grass_overlay):
		grass_overlay.queue_free()

func player_in_grass():
	var down_offset_pos = Vector2.ZERO
	down_offset_pos.y = 1
	var up_offset_pos = Vector2.ZERO
	up_offset_pos.y = -1
	
	
	grass_overlay = Node2D.new()
	grass_overlay.position = down_offset_pos
	
	var texture_overlay = TextureRect.new()
	texture_overlay.texture = grass_overlay_texture
	texture_overlay.position = up_offset_pos
	
	var grass_step_effect = GrassStepEffect.instantiate()
	grass_step_effect.position = up_offset_pos
	
	grass_overlay.add_child(grass_step_effect)
	grass_overlay.add_child(texture_overlay)
	self.add_child(grass_overlay)

func _on_Area2D_body_entered(_body):
	anim_player.play("Stepped")
	player_in_grass()
	encounter_grammarite(0.1)

func encounter_grammarite(chance):
	var player = Utils.get_player()
	if player.walk_speed > 4:
		chance *= 2
	
	if randf() < chance:
		player.set_physics_process(false)
		Utils.get_scene_manager().transition_to_dialogue($DialogueRoot)
